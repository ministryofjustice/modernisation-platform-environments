# Integration Hub Downstream Mock API

This environment hosts the independently deployed downstream mock benefit-checker API for the Integration Hub flow.

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

After apply, use the outputs to retrieve:

- `api_endpoint`
- `basic_auth_secret_name`
- `ecr_repository_url`
- `app_deploy_role_arn`

Populate the real Basic auth secret value directly in AWS Secrets Manager after the initial apply. Terraform intentionally ignores later secret value changes.
