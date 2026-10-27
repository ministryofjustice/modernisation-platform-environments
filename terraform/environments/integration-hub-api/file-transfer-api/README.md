# File transfer API recovery component

Development replacement for the retired MFT API, following the Benefit Checker
component layout. This is new infrastructure in `integration-hub-api-development`
with isolated state at `environments/members/integration-hub-api/file-transfer-api`.
The old root and legacy state remain untouched. No production accounts are added.

## Deployment order

1. Merge the Modernisation Platform component registration. Wait for generated
   component platform files, state access and workspace provisioning; reconcile
   generated files before applying this component.
2. Apply the MFT development stack first. Its incoming bucket grants only the API
   upload role S3 upload/multipart access to enabled client prefixes. Its key grants
   GenerateDataKey/Decrypt through S3 for those prefixes and DescribeKey to API
   deployment roles. Full key ARN discovery uses the cross-account alias ARN.
3. Plan this component in workspace `integration-hub-api-development`. It is already
   deployed in development, so inspect updates against that state. Stop if the plan
   proposes legacy or Benefit Checker destruction. Apply after the MFT grants exist.
4. Create companion repository environment
   `integration-hub-api-file-transfer-api-development`, restricted to main. Merge
   the companion workflow change and run `deploy-development` to install handlers.
5. Populate credentials in the new account using the secret-name outputs. Placeholder
   credentials are rejected. Update consumers/Bruno with `transfer_ticket_api_endpoint`.
6. Exercise single PUT, multipart initiation, additional part URLs, completion and
   cancellation; verify incoming objects proceed through the MFT processing pipeline.

## API hostname

The `transfer_ticket_api_endpoint` output uses
`https://api.<environment>.file-transfer.service.justice.gov.uk` (for example,
`https://api.development.file-transfer.service.justice.gov.uk`). Production uses
`https://api.file-transfer.service.justice.gov.uk` when that environment is onboarded.
The AWS-generated endpoint remains enabled and is available as
`transfer_ticket_api_execute_api_endpoint` during migration.

Application code stays in `integration-hub-file-transfer-api`. Upload permissions
are restricted to the server-configured client prefixes; no caller supplies a prefix.
When changing clients in `application_variables.json`,
apply MFT first via its workflow_dispatch (the MFT workflow watches its own directory),
then this component. Existing browser CORS allows only the Transfer Web App origin;
API clients can use Bruno/CLI directly. Browser onboarding needs an explicit origin.

The recovery preserves existing authentication and upload routes. JWT, production
onboarding and per-client assumed roles remain separate design work. Alarm resources
exist but no SNS actions are wired to retired cross-account topics.

The API resources are defined directly in this component; there is no separate
module. The former `module.integration_hub_file_transfer_api` state addresses were
migrated with `moved` blocks, which have since been removed. The legacy root stack
and its module have been removed; the root backend now uses the standard
`environments/members/integration-hub-api` prefix and contains no resources.

Always update deployment branches from current `main` before planning. The MFT
root shares state with the dispatcher: applying stale code can revert resources
created by another branch. Review the full plan before approving an apply.
Environments without enabled API clients receive no API grants and do not require
an API account. Enabling a client requires its API account to exist first.

## What it does

The API protects uploads with Basic authentication for user-driven HTTPS uploads,
bearer-token authentication for system-to-system integrations, and role-based
authorisation that maps callers to permitted `clientId` values. Credentials are held
in Secrets Manager.

1. A caller sends `POST /transfer-tickets` to API Gateway with a Basic auth header or
   a bearer token.
2. API Gateway invokes a Lambda request authorizer. Its result is cached for
   300 seconds per `Authorization` header.
3. The authorizer validates the caller against Secrets Manager and resolves the
   caller's role mapping from DynamoDB.
4. The upload-ticket Lambda reads client upload configuration from DynamoDB and
   verifies that the caller may request a ticket for the requested `clientId`.
5. For files at or below the single PUT limit, it returns a short-lived pre-signed
   `PUT` URL for the Managed File Transfer incoming bucket.
6. For larger files, it starts an S3 multipart upload, stores the upload session, and
   returns the first batch of pre-signed part URLs plus the follow-up operations for
   more parts, completion and abort.
7. The client uploads directly to S3 and, for multipart uploads, completes the upload
   through the API.
8. When the file reaches the MFT `clean` bucket, the downstream notifier publishes an
   SNS event with the `clientId`, `transferTicket`, file details and a pre-signed
   download URL.

## Authentication configuration

[`application_variables.json`](application_variables.json) supports an
`auth_configuration` block per environment:

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

After apply, the created secret names are available as Terraform outputs
(`user_auth_secret_names`, `system_auth_secret_names`). Terraform creates the secret
containers only. Live secret values are managed operationally in Secrets Manager and
ignored by Terraform after creation; the authorizer reads the current value at
request time.

A user secret holds:

```json
{ "username": "products-poc-user", "password": "<password>", "roleName": "products-poc-upload" }
```

A system principal secret holds the following. Callers send the bearer token as
`<tokenId>.<bearerToken>`:

```json
{ "tokenId": "products-poc-api", "bearerToken": "<token>", "roleName": "products-poc-upload" }
```

## Lambda code deployment

Terraform creates the Lambda functions with bootstrap placeholder code from
`bootstrap-lambdas/`, which returns `503` responses. The real code lives in
`ministryofjustice/integration-hub-file-transfer-api` and is deployed by its
`deploy-development` workflow, which uses the OIDC role in the
`app_deploy_role_arn` output. Terraform ignores later code changes.

If an apply changes a Lambda's `filename` (for example, when the bootstrap build path
changes), it overwrites the live code with the placeholder. In that case, re-run
`deploy-development`, then wait up to 5 minutes for the authorizer cache to expire
before testing.

## Contract and tests

The OpenAPI contract, Lambda unit tests, Bruno collection and example API calls are in
the companion repository `integration-hub-file-transfer-api`.
