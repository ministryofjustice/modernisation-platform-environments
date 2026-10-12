# GitHub Copilot Instructions

## Language and Style

- Use British English spelling throughout
- Follow conventional commit message format

## Ministry of Justice Standards

- Adhere to guidance published under [ministryofjustice/.github](https://github.com/ministryofjustice/.github)
- Follow security best practices for government services

## Terraform

- Follow the Modernisation Platform's [Terraform Style Guide](https://user-guide.modernisation-platform.service.justice.gov.uk/team/terraform-style-guide)
- Do not append the resource type to the resource name (e.g., use `my-resource` instead of `my-resource-s3-bucket`)
- Use kebab case for resource names (e.g., `my-resource-name`)
- Include comments for complex logic or non-obvious decisions
- Centralise Step Functions IAM permission definitions in `step_functions_common.tf` within each Terraform root; do not scatter them across individual workflow files.
- Reuse the common Step Functions execution role and policy, and the shared script-runner ECS task role and policy. Keep orchestration and script-runtime permissions attached to their respective roles; individual `step_functions_*.tf` workflow files must not introduce per-function IAM policies.
