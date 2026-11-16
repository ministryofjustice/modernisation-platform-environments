# Integration Hub Downstream Mock API

This environment hosts the independently deployed downstream mock benefit-checker API for the Integration Hub flow.

The service module is enabled only in the `integration-hub-development` workspace while the MVP deployment location is being validated. Other Integration Hub workspaces retain only the platform-generated component configuration.

## Target architecture

- API Gateway HTTP API provides the external endpoint.
- API Gateway uses a VPC link to an internal ALB.
- The ALB forwards to an ECS/Fargate service running the Kotlin downstream mock API.
- The application itself enforces HTTP Basic authentication using credentials stored in Secrets Manager.

## Terraform commands

```bash
cd terraform/environments/integration-hub/downstream-mock-api
terraform init -reconfigure
terraform workspace select integration-hub-development
terraform plan
```

## Runtime configuration

The ECS service expects the companion application repository to publish a container image to the created ECR repository.

The Modernisation Platform component workflow owns the generated `platform_*.tf`, backend, provider, networking and version files at the component root. Service-specific infrastructure is isolated in `modules/service`.

After apply, use the outputs to retrieve:

- `api_endpoint`
- `basic_auth_secret_name`
- `ecr_repository_url`
- `app_deploy_role_arn`

Terraform bootstraps a generated Basic auth password in Secrets Manager for the initial deployment. Later secret value updates are intentionally ignored by Terraform, and ECS reads the secret only when a task starts, so rotate credentials by updating the secret in AWS Secrets Manager and forcing a new ECS deployment.
