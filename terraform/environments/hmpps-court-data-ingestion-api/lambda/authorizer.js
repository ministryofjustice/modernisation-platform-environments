
const crypto = require('crypto');
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
const secretsClient = new SecretsManagerClient();
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
  console.log(`[auth] signature header present=$${Boolean(signatureHeader)} len=$${signatureHeader ? String(signatureHeader).length : 0} preview=$${preview(signatureHeader)}`);

  if (!signatureHeader) {
    console.log("[auth] deny: missing signatureHeader");
    return {
      statusCode: 403,
      body: JSON.stringify({ message: "missing signatureHeader" })
    };
  }

  try {
    if (!cachedSecret) {
      console.log("[auth] fetching secret from Secrets Manager", "SECRET_ID=", process.env.SECRET_ID);
      const command = new GetSecretValueCommand({ SecretId: process.env.SECRET_ID });
      const response = await secretsClient.send(command);
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
      const SQS_URL = process.env.SQS_URL;
      const config = {}; // type is SQSClientConfig
      const sqsClient = new SQSClient(config);
      const input = { // SendMessageRequest
        QueueUrl: SQS_URL, // required
        MessageBody: rawBody, // required
      };
      const command = new SendMessageCommand(input);
      const response = await sqsClient.send(command);
      return {
        statusCode: 200
      };
    }

    console.log("[auth] deny: token mismatch", "tokenPreview=", preview(receivedSignature), "secretPreview=", preview(computedSignature));
    return {
      statusCode: 403,
      body: JSON.stringify({ message: "Token did not match" })
    };

  } catch (error) {
    console.log("[auth] deny: error verifying token:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "error" })
    };
  } finally {
    console.log("[auth] end");
  }
};