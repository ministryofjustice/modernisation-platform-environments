# Stage 3: Forge formal-governance infrastructure

Companion to the application-builder declaration UI and formal-assessment PRs.
Do not apply until the API image is published and its immutable digest reviewed.
No image, token value or live AWS configuration is provisioned by opening this PR.

## What this adds

- A separate private Fargate assessment service with a Bedrock-only task role.
- Internal HTTPS ALB and DNS-validated certificate. Security groups accept
  assessment calls from Forge tasks only; the API has no public IP or public ingress.
- A shared 64-character Secrets Manager token injected into both containers by ECS.
- Forge environment/secret wiring and the existing execution role's permission to
  inject that token. API health checks, CloudWatch logs and deployment rollback.
- Read-only API filesystem and a non-root owned scratch volume matching the
  `VOLUME /scratch` declaration in the application API image.

The internal ALB and running API task add infrastructure cost; review that footprint
before applying. The existing shared Bedrock policy is reused rather than widened.
The API does not receive Forge's application task role or its S3/EFS privileges.

## Coordinated rollout

1. Merge the dormant UI foundation independently. Review the formal backend and
   infrastructure together. The backend PR builds the API image from
   `governance/Dockerfile`, tagged `governance-build-<commit>` in shared ECR.
2. Publish the reviewed API image through the approved image pipeline and capture
   its ECR digest. The enforced Forge deployment gate must remain blocked until
   the dependency is ready; do not bypass mandatory governance.
3. Plan this component in development with `forge_governance_enabled=true` and
   `forge_governance_image=<shared-ECR-repository>@sha256:<reviewed-digest>`.
   Defaults create no governance resources and do not change current Forge settings.
   This variable controls infrastructure provisioning, not policy approval.
4. Review the enabled plan and apply using the existing environments approval flow.
   Verify certificate validation, healthy targets, service logs and real Bedrock
   assessment. Health alone does not verify IAM/model access or approval semantics.
5. The Forge ECS service ignores Terraform changes to `task_definition`. Registering
   its configured revision is not enough: use the approved release process to make
   that revision active while retaining the last working Forge image. Do not blindly
   roll back the current image tag to the Terraform variable's older value.
6. From Forge's network, test an eligible request, unknown answers, unsupported
   scope and assessment outages with the injected service credential. Collect
   decisions and reasons without printing the token or any real user data.
7. Record the infrastructure revision and acceptance evidence, then set GitHub
   environment `FORGE_GOVERNANCE_ROLLOUT_READY=true` for the development account.
   Release the enforced Forge image through its guarded application pipeline.
8. Verify declaration/candidate assessment, saved-session errors and packaging on
   the hosted development page. Repeat all prerequisites independently for production.

Rotate the shared token only with a coordinated restart of both services. Keep
rollout readiness blocked until live formal assessment passes. The application
pipeline's metadata guard cannot establish network, secret population, IAM or
model readiness by itself. No preview exception is available.

## Validation

Terraform formatting and provider/schema validation were run locally with
`terraform init -backend=false` and `terraform validate`. No AWS plan, apply,
resource creation, secret read or live assessment was performed. An enabled plan,
security review and live development acceptance remain required before approval.
