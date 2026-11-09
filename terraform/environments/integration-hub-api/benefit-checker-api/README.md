# Integration Hub Benefit Checker API

Development-only infrastructure for the interim benefit-checker API. This is a
per-API component in the `integration-hub-api` account, rather than part of the
shared `platform` component.

The boundary is intentional:

- `networking` owns account/VPC-level resources when required.
- `platform` will own shared API-hosting capabilities and shared metadata.
- `benefit-checker-api` owns only this API's runtime infrastructure while the
  shared hosting platform is being developed.

The component creates an HTTP API Gateway, request-authorizer and orchestration
Lambdas, DynamoDB authentication mappings, Secrets Manager client credentials,
access and application logs, throttling, CloudWatch alarms, and a narrowly
scoped GitHub OIDC deployment role.

The public health route is `GET /health`. The authenticated client route is
`POST /v1/benefit-checks/assessments`. Application code and OpenAPI are in
`ministryofjustice/integration-hub-api-platform`.

Resources are gated by `local.is-development`. The downstream mock API must
exist before applying this component. The component creates a consumer-owned
Secrets Manager secret for the downstream Basic credential because the mock
provider is hosted in a separate AWS account. Its bootstrap value is unusable
until it is populated operationally from the provider credential.

## Deployment sequence

1. Register `benefit-checker-api` in
   `modernisation-platform/environments/integration-hub-api.json`.
2. Wait for Modernisation Platform to generate this component's platform files,
   backend and development workspace.
3. Merge `main` into this branch and plan workspace
   `integration-hub-api-development`.
4. Apply the component and set the application repository environment
   `integration-hub-api-benefit-checker-api-development` variable
   `AWS_DEPLOY_ROLE_ARN` from the `app_deploy_role_arn` output.
5. Populate `downstream_basic_auth_secret_name` with the downstream mock
   credential using an operational, out-of-band secret copy.
6. Replace the generated client credential placeholders in Secrets Manager.
7. Deploy both application Lambda packages and execute the end-to-end test.

The previously deployed proof-of-concept resources remain in their legacy
state until this isolated replacement has been tested. Their removal is a
separate, explicitly planned cleanup to avoid disrupting the working demo.

## Entra caller authentication

The assessment route uses API Gateway's native JWT authorizer. It verifies the
signature, issuer, audience and token lifetime. The application checks v2
application tokens (`idtyp=app`), the `BenefitChecker.Assess` role and an explicit
consumer client-ID allowlist. Health remains public.

Use a dedicated benefit-checker API registration, not the file-transfer API's
registration or upload permission. Configure `entra.api_audience` with its API
client ID and `entra.allowed_client_ids` with approved consumer application IDs.
The DEVL tenant, API and consumer IDs are configured from the successful IDAM
apply. A precondition continues to block missing or malformed identity settings.

The former caller Basic/shared-token secrets and tables remain in state during
migration, but the JWT route does not use them. The old Lambda authorizer invoke
permission is removed. Resource cleanup can follow a verified deployment.
The separate downstream provider Basic credential is unchanged.

Coordinate a development maintenance window: deploy the matching application
change and apply this component, then test a real Entra token. Legacy clients
are denied during the migration. Do not merge the application PR until the
registrations and infrastructure are ready, since merging deploys code.

Before sign-off, verify a valid token returns an assessment; missing, expired,
invalid-signature and wrong-audience tokens receive 401 from API Gateway; valid
tokens with no assessment role or an unapproved consumer receive 403 from the
application. Unit tests exercise claim policy only, not JWT signature validation.

The dedicated registrations are requested in
[IDAM #1014](https://github.com/ministryofjustice/staff-identity-idam-entra-infra/pull/1014).
After IDAM applies it, use the `pilot_api_configuration` output to populate this
component's `entra.api_audience` and `entra.allowed_client_ids`. The client uses
its `token_scope`. No credentials belong in application_variables.json.

The registration apply succeeded in
[run 42643076503](https://github.com/ministryofjustice/staff-identity-idam-entra-infra/actions/runs/42643076503).
The development IDs come from its `pilot_api_configuration` output. These are
public configuration identifiers; no client credential is stored here.
