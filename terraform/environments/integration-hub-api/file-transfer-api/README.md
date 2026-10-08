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

Application code stays in `integration-hub-file-transfer-api`. Upload permissions
are restricted to the server-configured client prefixes; no caller supplies a prefix.
When changing clients in `../modules/file-transfer-api/application_variables.json`,
apply MFT first via its workflow_dispatch (the MFT workflow watches its own directory),
then this component. Existing browser CORS allows only the Transfer Web App origin;
API clients can use Bruno/CLI directly. Browser onboarding needs an explicit origin.

The recovery preserves existing authentication and upload routes. JWT, stable custom
domains, production onboarding and per-client assumed roles remain separate design
work. Alarm resources exist but no SNS actions are wired to retired cross-account topics.

The module is copied from the legacy module so its changes cannot trigger the old
root deployment through shared-module change detection. Consolidate only after the
legacy state has been audited and deliberately retired.

Always update deployment branches from current `main` before planning. The MFT
root shares state with the dispatcher: applying stale code can revert resources
created by another branch. Review the full plan before approving an apply.
Environments without enabled API clients receive no API grants and do not require
an API account. Enabling a client requires its API account to exist first.
