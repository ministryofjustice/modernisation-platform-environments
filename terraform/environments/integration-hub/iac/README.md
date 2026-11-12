# Integration Hub PagerDuty infrastructure

This Terraform configuration creates the AWS resources needed by the
PagerDuty Terraform configuration in
`ministryofjustice/integration-hub/terraform/pagerduty`. It does not connect
to PagerDuty itself.

The resources are created only in the `integration-hub-production` workspace.
The production plan adds 12 resources; plans for development, test and
preproduction make no changes. This configuration has its own state in
`modernisation-platform-terraform-state`.

## What this creates

### Terraform state bucket

The `integration-hub-production-pagerduty-tfstate` bucket stores PagerDuty's
Terraform state. Versioning is enabled, public access and SSE-C are blocked,
and connections must use TLS.

The bucket policy denies access to everyone except these roles:

- The account's SSO `platform-engineer-admin` role
- `MemberInfrastructureAccess`
- `github-actions-plan`
- `github-actions-apply`
- `/github-actions/integration-hub-pagerduty`

### API key secret

The `pagerduty/api-key` secret is created without a value or a secret
version. It has the tag `credential-expiration=none`. An authorised person
must add the PagerDuty API token after the first apply.

### Encryption keys

The bucket and secret each have a KMS key. Both keys have rotation enabled
and default key policies disabled. The permitted roles can use the bucket key
only through S3 and the secret key only through Secrets Manager. For the
secret key, those roles are the SSO admin, `MemberInfrastructureAccess` and
PagerDuty roles.

### GitHub Actions role

The PagerDuty role uses version `6.8.2` of the IAM `iam-role` module. It
trusts the account's GitHub OIDC provider only when the audience is
`sts.amazonaws.com` and the subject is
`repo:ministryofjustice/integration-hub:environment:pagerduty-production`.

The role can:

- List, read and write `pagerduty/terraform.tfstate` and its `.tflock` file.
- Use the state key through S3.
- Read the API key secret over TLS and decrypt it through Secrets Manager.

It cannot delete state or write the secret.

## Before deploying

You need Terraform 1.11 or later, but below 2.0, the Modernisation Platform
generated files and the `environment_management` secret. The production
account is defined in `environments/integration-hub.json` in
`ministryofjustice/modernisation-platform`. The workflow supplies the
workspace.

PagerDuty settings are in `locals-pagerduty.tf`. Do not edit `platform_*.tf`,
`platform_base_variables.tf` or `networking.auto.tfvars.json`; they are
generated files.

Before making changes, run `terraform fmt`, `terraform init -backend=false`
and `terraform validate`. Run plans and applies only through GitHub Actions.

## Deployment

1. Merge the pull request. The integration-hub workflow plans the change and,
   with the usual approval, applies it to production.
2. After the first apply, an authorised person adds the PagerDuty API token to
   the secret in Secrets Manager. Do not put the token in code or Terraform;
   this configuration does not read or store it.
3. In `integration-hub`, create the `pagerduty-production` GitHub environment.
   Limit deployments to `main`, require reviewers and turn off admin bypass.
   Add the role ARN and state KMS key ARN as environment secrets.
4. Run the PagerDuty Terraform workflow in that repository, plan-only for now.
   The environment and workflow do not yet exist.

Pass backend settings to `terraform init` using `-backend-config`; do not
commit them. Include `kms_key_id`, because `encrypt=true` alone uses SSE-S3
rather than the KMS key.

## Known gaps

- The generated `platform_secrets.tf` reads `environment_management` as an
  ordinary data source, so its value is stored in this configuration's state.
  This is not the PagerDuty token.
- The state bucket has no S3 access logging or lifecycle rule. The team still
  needs to agree how long to retain state.
- Secret rotation is disabled. PagerDuty token rotation is manual.
