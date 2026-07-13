# Integration Hub API Platform

This environment is the active Modernisation Platform home for the Integration Hub Managed File Transfer API infrastructure.

The Lambda application code, OpenAPI contract, and API request collections live in the companion repository `ministryofjustice/integration-hub-file-transfer-api`.

This repository now stays infrastructure-only. Terraform creates the API Gateway, IAM, DynamoDB, and bootstrap Lambda resources here; the companion repository owns deployment of the real Lambda code through a separate app workflow using GitHub OIDC into the member account.

It protects the API with:

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

## Terraform commands

Apply the Managed File Transfer stack first so it creates the SSM parameters for the upload bucket consumed by this stack:

```bash
cd terraform/environments/integration-hub/managed-file-transfer
terraform init -reconfigure
terraform workspace select integration-hub-development
terraform plan
```

Then initialise and plan the API platform stack from its new owning environment:

```bash
cd terraform/environments/integration-hub-api
terraform init -reconfigure
terraform workspace select integration-hub-development
terraform plan
```

Phase 1 note: this environment currently uses the legacy `integration-hub/api-platform` backend path and workspace name to avoid a disruptive state migration during the repo split. The state cutover steps are documented in [STATE_MIGRATION.md](STATE_MIGRATION.md).

## Authentication configuration

`application_variables.json` supports an `auth_configuration` block per environment:

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

## Contract and tests

The source contract is documented in the companion repository's `openapi.yaml`.

The companion repository also contains the Lambda unit tests and Bruno request collection used to exercise the API.

After Terraform creates or updates the infrastructure here, deploy the real Lambda application code from `integration-hub-file-transfer-api` using the dedicated OIDC role exposed as `terraform output app_deploy_role_arn`. Until that app workflow runs, the API Lambdas return bootstrap `503` responses.

For the legacy-state cutover from `terraform/environments/integration-hub/api-platform`, see [STATE_MIGRATION.md](STATE_MIGRATION.md).
