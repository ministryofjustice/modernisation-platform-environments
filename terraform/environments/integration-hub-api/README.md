# Integration Hub API

This account (`integration-hub-api-development`) is split into components, each with its own Terraform state:

| Component | Purpose |
|---|---|
| [`file-transfer-api`](file-transfer-api/README.md) | Managed File Transfer upload-ticket API: API Gateway, Lambdas, DynamoDB, authentication secrets and observability |
| [`benefit-checker-api`](benefit-checker-api/README.md) | Benefit checker API |

The environment root deliberately contains no resources. Its backend uses the standard
`environments/members/integration-hub-api` prefix and only exists because the Modernisation
Platform pipeline always includes a root job.

Application code for the file transfer API lives in `ministryofjustice/integration-hub-file-transfer-api`.
