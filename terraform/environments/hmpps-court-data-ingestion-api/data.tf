#### This file can be used to store data specific to the member account ####

data "aws_secretsmanager_secret_version" "cloud_platform_account_id" {
  secret_id  = module.secret_cloud_platform_account_id.secret_id
  depends_on = [module.secret_cloud_platform_account_id]
}

data "archive_file" "authorizer" {
  type        = "zip"
  output_path = "${path.module}/authorizer.zip"

  source {
    content  = <<EOF
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const client = new SecretsManagerClient();
let cachedSecret;

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    const token = event.authorizationToken;
    const methodArn = event.methodArn;

    if (!token) {
        return generatePolicy('user', 'Deny', methodArn);
    }

    try {
        if (!cachedSecret) {
            console.log('Fetching secret from Secrets Manager');
            const command = new GetSecretValueCommand({ SecretId: process.env.SECRET_ID });
            const response = await client.send(command);
            cachedSecret = response.SecretString;
        }

        if (token === cachedSecret) {
             return generatePolicy('user', 'Allow', methodArn);
        }
        console.log('Token mismatch');
        return generatePolicy('user', 'Deny', methodArn);

    } catch (error) {
        console.log('Error verifying token:', error);
        return generatePolicy('user', 'Deny', methodArn);
    }
};

const generatePolicy = (principalId, effect, resource) => {
    const authResponse = {};
    authResponse.principalId = principalId;
    if (effect && resource) {
        const policyDocument = {};
        policyDocument.Version = '2012-10-17';
        policyDocument.Statement = [];
        const statementOne = {};
        statementOne.Action = 'execute-api:Invoke';
        statementOne.Effect = effect;
        statementOne.Resource = resource;
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }
    return authResponse;
};
EOF
    filename = "authorizer.js"
  }
}

