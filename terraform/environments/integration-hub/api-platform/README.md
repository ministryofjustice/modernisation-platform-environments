# Integration Hub API Platform

This component provides a thin API layer for Managed File Transfer uploads.

## What it does

1. A client calls `POST /transfer-tickets` on API Gateway.
2. API Gateway invokes a Lambda function.
3. The Lambda function reads client upload configuration from DynamoDB.
4. The Lambda function generates a short-lived S3 pre-signed `PUT` URL for the existing Managed File Transfer upload bucket.
5. The client uploads the file directly to S3 with the returned URL and headers.

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

## Example response shape

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

## Terraform commands

Apply the Managed File Transfer stack first so its remote state exposes the upload bucket output:

```bash
cd /Users/harsh.vasudev/IdeaProjects/modernisation-platform-environments/terraform/environments/integration-hub/managed-file-transfer
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

## Example API call

Replace `<api-endpoint>` with the `transfer_ticket_api_endpoint` Terraform output after apply.

```bash
curl -X POST "https://<api-endpoint>/transfer-tickets" \
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
