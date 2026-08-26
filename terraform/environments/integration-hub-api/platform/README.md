# Integration Hub API Platform

Development-only MVP infrastructure for the upstream-facing Integration Hub
API platform. The platform currently exposes benefit-checker routes and is
named generically so it can host additional downstream integrations over time.

The stack creates an HTTP API Gateway, request-authorizer and orchestration
Lambdas, DynamoDB authentication mappings, Secrets Manager client credentials,
access and application logs, throttling, CloudWatch alarms, and a narrowly
scoped GitHub OIDC deployment role.

The public health route is `GET /health`. The authenticated client route is
`POST /v1/benefit-checks/assessments`. Application code and OpenAPI are owned by
`ministryofjustice/integration-hub-api-platform`.

Resources are gated by `local.is-development`. The downstream mock API and its
credential secret must exist before applying this stack.

## Deployment sequence

1. Merge the Modernisation Platform component registration PR.
2. Merge main into this branch to receive the automatically generated platform files.
3. Plan and apply workspace `integration-hub-development` via the
   `integration-hub-api` workflow.
4. Set repository environment `integration-hub-api-platform-development`
   variable `AWS_DEPLOY_ROLE_ARN` to the `app_deploy_role_arn` output.
5. Replace the generated client credential placeholder in Secrets Manager.
6. Merge the application PR to deploy both Lambda packages.

Note: this README line is intentionally present to retrigger GitHub Actions on PR `#18570` after the component refactor.
