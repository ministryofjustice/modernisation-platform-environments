# Integration Hub API Platform

This component provides a thin API layer for Managed File Transfer uploads.

It now protects the API with:

1. Basic authentication for user-driven HTTPS uploads using Secrets Manager-held credentials.
2. Bearer token authentication for system-to-system API integrations using Secrets Manager-held tokens.
3. Role-based authorisation that maps callers to one or more permitted `clientId` values.

## What it does

1. A caller sends `POST /transfer-tickets` to API Gateway with either a Basic auth header or a Bearer token.
2. API Gateway invokes a Lambda request authorizer.
3. The authorizer validates the caller against Secrets Manager credentials or bearer tokens and resolves the caller's role mapping from DynamoDB.
4. The upload-ticket Lambda reads client upload configuration from DynamoDB.
5. The upload-ticket Lambda verifies that the authenticated caller is allowed to request a ticket for the requested `clientId`.
6. For files at or below the single PUT limit, the Lambda generates a short-lived pre-signed `PUT` URL for the existing Managed File Transfer upload bucket.
7. For larger files, the Lambda initiates an S3 multipart upload, persists the upload session, and returns the first batch of pre-signed part URLs plus follow-up API operations for the remaining parts, completion, and abort.
8. The client uploads directly to S3 and, for multipart flows, completes the upload through the API once all parts have been transferred.
9. When the file reaches the Managed File Transfer `clean` bucket, the downstream notifier publishes a client-facing SNS event containing the `clientId`, `transferTicket`, file details, and a presigned download URL.

## Sample request payload

```json
{
  "clientId": "products-poc",
  "fileName": "example-upload.csv",
  "contentType": "text/csv",
  "sizeBytes": 12345,
  "requestedExpirySeconds": 900,
  "contentMd5": "CY9rzUYh03PK3k6DJie09g=="
}
```

## Example single-upload response shape

```json
{
  "transferTicket": "f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61",
  "clientId": "products-poc",
  "upload": {
    "method": "PUT",
    "url": "https://...",
    "headers": {
      "Content-Type": "text/csv",
      "Content-MD5": "CY9rzUYh03PK3k6DJie09g==",
      "x-amz-meta-client-id": "products-poc",
      "x-amz-meta-declared-size-bytes": "12345",
      "x-amz-meta-original-file-name": "example-upload.csv",
      "x-amz-meta-transfer-ticket": "f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61",
      "x-amz-server-side-encryption": "aws:kms",
      "x-amz-server-side-encryption-aws-kms-key-id": "arn:aws:kms:eu-west-2:123456789012:key/..."
    },
    "expiresInSeconds": 900
  },
  "object": {
    "bucket": "integration-hub-unscanned-...",
    "key": "products-poc/uploads/2026/06/09/uuid.csv"
  }
}
```

## Example multipart response shape

```json
{
  "transferTicket": "f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61",
  "clientId": "products-poc",
  "object": {
    "bucket": "integration-hub-unscanned-...",
    "key": "products-poc/uploads/2026/06/09/uuid.csv"
  },
  "multipart": {
    "uploadId": "abc123...",
    "partSizeBytes": 67108864,
    "totalParts": 160,
    "maxParts": 10000,
    "expiresInSeconds": 900,
    "initialParts": [
      {
        "partNumber": 1,
        "method": "PUT",
        "url": "https://...",
        "headers": {},
        "expiresInSeconds": 900
      }
    ],
    "operations": {
      "presignPartsPath": "/transfer-tickets/f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61/parts",
      "completePath": "/transfer-tickets/f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61/complete",
      "abortPath": "/transfer-tickets/f2e7fd50-f0c5-4f8c-b0ad-f27c0c4d2b61"
    }
  }
}
```

## Terraform commands

Apply the Managed File Transfer stack first so it creates the SSM parameters for the upload bucket (consumed by this stack):

```bash
cd terraform/environments/integration-hub/managed-file-transfer
terraform init -reconfigure
terraform workspace select integration-hub-development
terraform plan
```

Then initialise and plan the API platform stack:

```bash
cd terraform/environments/integration-hub/api-platform
terraform init -reconfigure
terraform workspace select integration-hub-development
terraform plan
```

## Authentication configuration

`application_variables.json` now supports an `auth_configuration` block per environment:

```json
{
  "auth_configuration": {
    "roles": {
      "products-poc-upload": {
        "allowed_client_ids": ["products-poc"]
      }
    },
    "users": {
      "products-poc-user": {
        "enabled": true,
        "role_name": "products-poc-upload"
      }
    },
    "system_principals": {
      "products-poc-api": {
        "enabled": true,
        "role_name": "products-poc-upload"
      }
    }
  }
}
```

After apply, retrieve the created secret names from the Terraform outputs:

```bash
terraform output user_auth_secret_names
terraform output system_auth_secret_names
```

Terraform creates the secret containers, but the live secret values are managed operationally in AWS Secrets Manager and ignored by Terraform after creation. The authorizer resolves the current secret value from Secrets Manager at request time using the stored secret name.

For repeatable credential bootstrapping outside Terraform state, use:

```bash
scripts/bootstrap-api-credentials.sh user --secret-id <user-secret-name>
scripts/bootstrap-api-credentials.sh system --secret-id <system-secret-name>
```

The script generates the live credential locally, writes it to Secrets Manager, and prints only the one-time handover value to stdout.

Populate a user secret with JSON in this shape:

```json
{
  "username": "products-poc-user",
  "password": "replace-with-password",
  "roleName": "products-poc-upload"
}
```

Populate a system principal secret with JSON in this shape:

```json
{
  "tokenId": "products-poc-api",
  "bearerToken": "replace-with-token",
  "roleName": "products-poc-upload"
}
```

The bearer token supplied to the API is:

```text
<tokenId>.<bearerToken>
```

Example bootstrap flow for a user secret:

```bash
terraform output user_auth_secret_names
scripts/bootstrap-api-credentials.sh user --secret-id integration-hub-api-platform-development-user-products-poc-user
```

Example bootstrap flow for a system principal:

```bash
terraform output system_auth_secret_names
scripts/bootstrap-api-credentials.sh system --secret-id integration-hub-api-platform-development-system-products-poc-api
```

## Upload selection

The client always provides `sizeBytes`. The API uses that declared size to:

- reject requests above the configured 100 GB maximum for the client
- return a single pre-signed `PUT` upload for files up to the S3 single-request limit
- return a multipart upload session for files above the single-request limit

The declared size is stored as multipart session state and written into the uploaded object's S3 metadata for traceability.

## Example API call with Basic auth

Replace `<api-endpoint>` with the `transfer_ticket_api_endpoint` Terraform output after apply.

```bash
curl -X POST "https://<api-endpoint>/transfer-tickets" \
  -u "<username>:<password>" \
  -H "content-type: application/json" \
  -d '{
    "clientId": "products-poc",
    "fileName": "example-upload.csv",
    "contentType": "text/csv",
    "sizeBytes": 12345,
    "requestedExpirySeconds": 900,
    "contentMd5": "CY9rzUYh03PK3k6DJie09g=="
  }'
```

## Example API call with Bearer auth

```bash
curl -X POST "https://<api-endpoint>/transfer-tickets" \
  -H "authorization: Bearer <tokenId>.<token>" \
  -H "content-type: application/json" \
  -d '{
    "clientId": "products-poc",
    "fileName": "example-upload.csv",
    "contentType": "text/csv",
    "sizeBytes": 12345,
    "requestedExpirySeconds": 900,
    "contentMd5": "CY9rzUYh03PK3k6DJie09g=="
  }'
```

## Multipart follow-up calls

Request more part URLs:

```bash
curl -X POST "https://<api-endpoint>/transfer-tickets/<transfer-ticket>/parts" \
  -H "authorization: Bearer <tokenId>.<token>" \
  -H "content-type: application/json" \
  -d '{
    "partNumberStart": 11,
    "partNumberEnd": 20
  }'
```

Complete the multipart upload after collecting the `ETag` response header from each uploaded part:

```bash
curl -X POST "https://<api-endpoint>/transfer-tickets/<transfer-ticket>/complete" \
  -H "authorization: Bearer <tokenId>.<token>" \
  -H "content-type: application/json" \
  -d '{
    "parts": [
      { "partNumber": 1, "eTag": "\"etag-for-part-1\"" },
      { "partNumber": 2, "eTag": "\"etag-for-part-2\"" }
    ]
  }'
```

Abort a multipart upload if the transfer is abandoned:

```bash
curl -X DELETE "https://<api-endpoint>/transfer-tickets/<transfer-ticket>" \
  -H "authorization: Bearer <tokenId>.<token>"
```

## OpenAPI

The source contract is documented in [`openapi.yaml`](openapi.yaml).

After deployment, the same API publishes a protected Swagger UI and the raw OpenAPI document:

- `terraform output transfer_ticket_api_docs_url`
- `terraform output transfer_ticket_openapi_url`
- `terraform output transfer_ticket_api_docs_basic_auth_secret_name`

The docs page and raw OpenAPI URL are protected with browser-friendly HTTP Basic auth backed by Secrets Manager. Bootstrap the live password outside Terraform state with:

```bash
terraform output transfer_ticket_api_docs_basic_auth_secret_name
scripts/bootstrap-api-credentials.sh docs --secret-id <docs-secret-name>
```

Inside Swagger UI, callers should still use the API's own security schemes for actual operations:

- Basic auth credentials backed by Secrets Manager, or
- a Bearer token in the form `<tokenId>.<bearerToken>`

## Recommended sharing pattern

The standard pattern for sharing a Swagger contract with internal and external consumers is:

1. Host the human-friendly UI close to the API itself so the contract and runtime stay in sync.
2. Protect the UI with SSO or browser-friendly basic auth if broader internet reach is required.
3. Publish the raw OpenAPI document as a separate protected URL for code generation, Postman imports, and client automation.
4. Treat the OpenAPI file as versioned source alongside the implementation so contract changes are reviewed with code changes.

This stack now follows that pattern by serving `/docs` and `/openapi.yaml` from the same HTTP API, protecting the docs URLs with dedicated basic auth, and keeping the upload operations on their existing Basic and Bearer authentication controls.
