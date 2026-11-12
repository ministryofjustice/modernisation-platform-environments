# Integration Hub PagerDuty infrastructure

This component creates AWS resources for PagerDuty Terraform in
`ministryofjustice/integration-hub/terraform/pagerduty`. It never calls PagerDuty.
Only the `integration-hub-production` workspace creates them: its plan adds
12 resources; development, test and preproduction plan no changes. This
component's state is separate, in `modernisation-platform-terraform-state`.

## Resources and access

The versioned `integration-hub-production-pagerduty-tfstate` bucket blocks
public access and SSE-C, and requires TLS. Its policy denies everyone except
the account's SSO `platform-engineer-admin`, `MemberInfrastructureAccess`,
`github-actions-plan`, `github-actions-apply` and
`/github-actions/integration-hub-pagerduty` roles.

The `pagerduty/api-key` secret starts empty, with no version. Its tag is
`credential-expiration=none`. The bucket and secret each have a KMS key.
Both have rotation on and default key policies off; the listed roles can use
them only through S3 for the bucket or Secrets Manager for the secret. For
the secret key, the permitted roles are the SSO admin,
`MemberInfrastructureAccess` and PagerDuty roles.

The PagerDuty role uses the IAM `iam-role` module, version `6.8.2`. It trusts
the account's GitHub OIDC provider only with audience `sts.amazonaws.com` and
subject `repo:ministryofjustice/integration-hub:environment:pagerduty-production`.
It can list, read and write `pagerduty/terraform.tfstate` and its `.tflock`
file, use the state key through S3, and read the secret over TLS and decrypt
it through Secrets Manager. It cannot delete state or write the secret.

## Before you deploy

You need Terraform 1.11 or later, but below 2.0, the Modernisation Platform
generated files and the `environment_management` secret. The production account
is defined in `environments/integration-hub.json` in
`ministryofjustice/modernisation-platform`; the workflow supplies the workspace.

Do not edit `platform_*.tf`, `platform_base_variables.tf` or
`networking.auto.tfvars.json`; they are generated. PagerDuty values are in
`locals-pagerduty.tf`. Before changing anything, run `terraform fmt`,
`terraform init -backend=false` and `terraform validate`. Run plans and applies
only through GitHub Actions.

## Deploy

1. Merge the PR. The integration-hub workflow plans and, with the usual
   approval, applies production.
2. After the first apply, someone with access adds the PagerDuty API token to
   the secret in Secrets Manager. Never put it in code or Terraform; this
   component does not read or store it.
3. In `integration-hub`, create the `pagerduty-production` GitHub environment:
   limit deployments to `main`, require reviewers and turn off admin bypass.
   Add the role ARN and state KMS key ARN as environment secrets.
4. Run the PagerDuty Terraform workflow there, plan-only for now. Neither the
   environment nor the workflow exists yet.

Pass backend settings to `terraform init` with `-backend-config` and do not
commit them. Include `kms_key_id`: `encrypt=true` alone uses SSE-S3, not the
KMS key.

## Known gaps

- Generated `platform_secrets.tf` reads `environment_management` as an ordinary
  data source, so its value is in this component's state. It is not the
  PagerDuty token.
- The state bucket has no S3 access logging or lifecycle rule. The team still
  needs to agree state retention.
- Secret rotation is off; PagerDuty token rotation is manual.
