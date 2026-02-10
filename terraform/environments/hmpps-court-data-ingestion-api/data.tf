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

function preview(str) {
  if (!str) return "(none)";
  const s = String(str);
  if (s.length <= 12) return s.slice(0, 6) + "...";
  return s.slice(0, 6) + "..." + s.slice(-6);
}

exports.handler = async (event) => {
  console.log("[auth] start");
  console.log("[auth] Received event:", JSON.stringify(event, null, 2));

  // REQUEST authorizer passes headers in event.headers
  // Headers are not always lowercased by APIGW, so we check strictly or loosely
  const headers = event.headers || {};
  const token = headers["X-Signature"] || headers["x-signature"];
  const methodArn = event && event.methodArn;

  console.log(`[auth] token present=$${Boolean(token)} len=$${token ? String(token).length : 0} preview=$${preview(token)}`);
  console.log(`[auth] methodArn present=$${Boolean(methodArn)} value=$${methodArn || "(none)"}`);

  if (!methodArn) {
    console.log("[auth] deny: missing methodArn");
    return generatePolicy("user", "Deny", "*");
  }

  if (!token) {
    console.log("[auth] deny: missing token");
    return generatePolicy("user", "Deny", methodArn);
  }

  try {
    if (!cachedSecret) {
      console.log("[auth] fetching secret from Secrets Manager", "SECRET_ID=", process.env.SECRET_ID);
      const command = new GetSecretValueCommand({ SecretId: process.env.SECRET_ID });
      const response = await client.send(command);
      cachedSecret = response.SecretString;

      console.log(`[auth] secret fetched len=$${cachedSecret ? String(cachedSecret).length : 0} preview=$${preview(cachedSecret)}`);
    } else {
      console.log(`[auth] using cached secret len=$${cachedSecret ? String(cachedSecret).length : 0} preview=$${preview(cachedSecret)}`);
    }

    if (String(token) === String(cachedSecret)) {
      console.log("[auth] allow: token matched");
      return generatePolicy("user", "Allow", methodArn);
    }

    console.log("[auth] deny: token mismatch", "tokenPreview=", preview(token), "secretPreview=", preview(cachedSecret));
    return generatePolicy("user", "Deny", methodArn);

  } catch (error) {
    console.log("[auth] deny: error verifying token:", error);
    return generatePolicy("user", "Deny", methodArn);
  } finally {
    console.log("[auth] end");
  }
};

const generatePolicy = (principalId, effect, resource) => {
  const authResponse = {};
  authResponse.principalId = principalId;
  if (effect && resource) {
    const policyDocument = {};
    policyDocument.Version = "2012-10-17";
    policyDocument.Statement = [];
    const statementOne = {};
    statementOne.Action = "execute-api:Invoke";
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




