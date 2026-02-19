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
const crypto = require('crypto');
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
  let signatureHeader = headers["X-Signature"] || headers["x-signature"];

  // Fallback for TOKEN authorizer events (where signatureHeader is in authorizationToken)
  if (!signatureHeader && event.authorizationToken) {
    signatureHeader = event.authorizationToken;
  }
  const methodArn = event && event.methodArn;

  console.log(`[auth] signiture header present=$${Boolean(signatureHeader)} len=$${signatureHeader ? String(signatureHeader).length : 0} preview=$${preview(signatureHeader)}`);
  console.log(`[auth] methodArn present=$${Boolean(methodArn)} value=$${methodArn || "(none)"}`);

  if (!methodArn) {
    console.log("[auth] deny: missing methodArn");
    return generatePolicy("user", "Deny", "*");
  }

  if (!signatureHeader) {
    console.log("[auth] deny: missing signatureHeader");
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


    // Extract actual signature (assuming format: sha256=abcdef123...)
    const receivedSignature = signatureHeader.replace('sha256=', '');

    // IMPORTANT: Use raw body (API Gateway must pass it unmodified)
    const rawBody = event.body;

    // If body is base64 encoded (when using certain API Gateway configs)
    const bodyBuffer = event.isBase64Encoded
        ? Buffer.from(rawBody, 'base64')
        : Buffer.from(rawBody, 'utf8');

    // Compute HMAC
    const computedSignature = crypto
        .createHmac('sha256', cachedSecret)
        .update(bodyBuffer)
        .digest('hex');
        
    // Timing-safe comparison
    const isValid = crypto.timingSafeEqual(
        Buffer.from(receivedSignature, 'hex'),
        Buffer.from(computedSignature, 'hex')
    );

    if (isValid) {
      console.log("[auth] allow: token matched");
      return generatePolicy("user", "Allow", methodArn);
    }

    console.log("[auth] deny: token mismatch", "tokenPreview=", preview(receivedSignature), "secretPreview=", preview(computedSignature));
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




