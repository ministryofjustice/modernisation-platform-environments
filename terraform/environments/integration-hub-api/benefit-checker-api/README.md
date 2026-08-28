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
