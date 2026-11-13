---
description: "Integration Hub Terraform instructions. Relevant when working on Terraform files linked to the @ministryofjustice/integration-hub GitHub team."
source: https://github.com/ministryofjustice/ai-toolkit/blob/main/toolkits/integration-hub/.apm/instructions/terraform.instructions.md
---

# Terraform

## Structure

- data sources should be grouped with the relevant consuming modules or resources
- outputs should be placed in `outputs.tf`
- provider blocks should be placed in `providers.tf`
- variables should be placed in `variables.tf`
- version blocks should be placed in `versions.tf`

Resources should be grouped in files which are based on their name. For example:

- IAM roles and policies should be grouped according to their consuming modules or resources
  - E.g. `iam-guardduty.tf`
  - E.g. `iam-transfer.tf`
- KMS keys should be placed in `kms-keys.tf`
- Local values should be grouped according to their consumer
  - E.g. `locals-iam.tf`
  - E.g. `locals-kms.tf`

Reusable local modules should be placed in `modules/`

## Naming

- Resources should be named using snake_case. For example:
  `resource "aws_iam_role" "example_role_name" {}`

- Resource names should not repeat the resource type. For example:

  Preferred:
  `resource "aws_iam_role" "example_role_name" {}`
  Avoid:
  `resource "aws_iam_role" "example_role_name_role" {}`

- Modules should be named using snake_case. For example:
  `module "example_name" {}`

- Module names should be descriptive of their purpose. For example:
  - `module "kms_s3" {}`
  - `module "cloudwatch_eventbridge" {}`

## Conventions

- Where possible, use modules from the [terraform-aws-modules namespace](https://registry.terraform.io/namespaces/terraform-aws-modules)
- Use resources to manage infrastructure that is not available as a module, or to avoid
  cyclical dependencies
- Reference Terraform modules using exact version parameters
  - e.g. `module "example_name" { source = "terraform-aws-modules/example_name/aws" version = "x.y.z" }`
- Prefer stable, well-defined inputs over defensive coding
- Avoid nested try, coalesce, and implicit defaults that obscure intent or mask configuration errors

### Modernisation Platform Environments

- When working in github.com/ministryofjustice/modernisation-platform-environments, make no changes to files matching `platform_**.tf`
- Assume any directory containing files matching `platform_**.tf` defines the root of a Terraform configuration
- If a requested change requires editing any file in `.github/`, make no edits to it and state the file path and the reason in your reply.
