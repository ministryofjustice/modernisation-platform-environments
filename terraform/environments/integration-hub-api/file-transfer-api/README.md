# File transfer API recovery component

Development replacement for the retired MFT API, following the Benefit Checker
component layout. This is new infrastructure in `integration-hub-api-development`
with isolated state at `environments/members/integration-hub-api/file-transfer-api`.
The old root and legacy state remain untouched. No production accounts are added.

## Initial infrastructure setup

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
5. Configure the approved Entra registration IDs and consumer grants using the cutover
   instructions below. Only the documentation routes retain separate Basic credentials.
   Update consumers/Bruno with `transfer_ticket_api_endpoint`.
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

Upload routes use Entra JWT authentication after the coordinated cutover below.
Production onboarding and per-client assumed roles remain separate design work.
Alarm resources exist but no SNS actions are wired to retired cross-account topics.

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

## Upload flow

1. The consumer obtains an application access token from the approved Entra tenant.
2. API Gateway validates the JWT signature, issuer, audience and token lifetime.
3. The upload handler checks the application token type, `FileTransfer.Upload` role
   and explicit consumer application-to-client mapping before accessing uploads.
4. The handler reads the client's upload configuration and issues a short-lived S3
   PUT URL or starts a multipart upload with part URLs and follow-up operations.
5. The client uploads directly to S3 using the exact returned headers. Multipart
   clients request additional parts and complete or abort through authenticated routes.
6. The file-transfer service scans and routes uploaded files. Configured pickup
   notifications link to authenticated pickup; this API does not issue download URLs.

## Legacy authentication resources

The `auth_configuration` block, credential containers and authentication tables are
retained temporarily to avoid destructive cleanup during cutover. Their Basic and
static bearer credentials no longer authorise upload routes. Do not populate them
as part of OAuth2 onboarding. Documentation credentials remain separate.

## Lambda code deployment

Terraform creates the Lambda functions with bootstrap placeholder code from
`bootstrap-lambdas/`, which returns `503` responses. The real code lives in
`ministryofjustice/integration-hub-file-transfer-api` and is deployed by its
`deploy-development` workflow, which uses the OIDC role in the
`app_deploy_role_arn` output. Terraform ignores later code changes.

If an apply changes a Lambda's `filename` (for example, when the bootstrap build path
changes), it overwrites the live code with the placeholder. In that case, re-run
`deploy-development` before testing. Upload routes use the JWT authorizer rather
than the retired Lambda authorizer cache.

## Contract and tests

The OpenAPI contract, Lambda unit tests, Bruno collection and example API calls are in
the companion repository `integration-hub-file-transfer-api`.


## Entra OAuth2 cutover (configuration required before apply)

Upload routes now use the API Gateway JWT authorizer. Configure `accounts.<environment>.entra`
in `application_variables.json` with approved, real IDs:

```json
{
  "tenant_id": "<MoJ tenant UUID>",
  "api_audience": "<file-transfer API application UUID>",
  "application_clients": {
    "<products-poc consumer application UUID>": ["products-poc"]
  }
}
```

The API application and consumer registration must be distinct. Request v2 access tokens,
add the `idtyp` optional access-token claim, expose the application-only role
`FileTransfer.Upload`, require assignment and grant/admin-consent that role to the consumer.
Entra application roles are checked in the upload Lambda; they are not OAuth delegated
scopes, so API Gateway `authorization_scopes` is deliberately not configured.

Missing IDs/mappings block the Terraform plan. No tenant or consumer identity has been
invented. Add production-specific registrations and grants before production deployment.

Coordinate this change with the companion application's OAuth2 PR: deploy the new
application first (it rejects legacy authorizer contexts), then apply this component.
There is an intentional deny-all interval; schedule it. Do not restore the old application
while JWT routes are active. A rollback must be coordinated and must not silently restore
Basic access. Docs retain their separate Basic credentials.

The retired authorizer is replaced with a deny-only bootstrap and loses credential/table
read permissions and gateway invocation permission. Existing credential containers and
auth tables are retained to avoid destructive credential/state cleanup in this cutover;
none authorises an upload route. Delete these separately after acceptance.

Validate with real Entra tokens before merge/deployment approval: valid application,
wrong audience/issuer, expired/invalid signature, delegated user, missing application role,
unmapped application, and cross-client access on all multipart operations. Unit tests in
the application cover handler authorisation, not AWS cryptographic token validation.

Production acceptance additionally needs payload/encryption/connectivity evidence,
zero-critical-error smoke results and Buyer SecOps/Infra sign-off. This authentication
change alone does not complete D07. Existing alarm actions are not wired; agree the
operational alert destinations before production activation.


## IDAM registrations and automated development testing

Registration [IDAM PR #962](https://github.com/ministryofjustice/staff-identity-idam-entra-infra/pull/962)
is merged. Merging does not itself supply the deployed registration IDs to this
component. Obtain the `file_transfer_configuration` output from the IDAM deployment:

| IDAM output | This component's `entra` setting | API test environment variable |
| --- | --- | --- |
| `tenant_id` | `tenant_id` | `ENTRA_TENANT_ID` |
| `api_audience` | `api_audience` | `ENTRA_API_CLIENT_ID` |
| `consumer_client_id` | Key in `application_clients`, mapped to `["products-poc"]` | `ENTRA_CONSUMER_CLIENT_ID` |

Use the API application UUID as the v2 token audience, not its `api://` URI. The
consumer uses `api_application_id_uri` plus `/.default` when requesting a token.

[IDAM PR #967](https://github.com/ministryofjustice/staff-identity-idam-entra-infra/pull/967)
adds GitHub trust to the development consumer. The API repository's protected
`file-transfer-api-entra-development` environment permits only `main`, requires
an Integration Hub reviewer, and disables self-approval and administrator bypass.
Its identity trust belongs in IDAM Terraform, not in this AWS component.

After IDAM apply, configure the three non-secret GitHub environment identifiers,
complete the coordinated API cutover, then run **Test Entra development authentication**
from `main`. It checks basic authentication failures and uploads a harmless file.
It does not replace the broader token, multipart, scan and download acceptance tests.
No changes to platform-managed workflows are needed for these tests.
