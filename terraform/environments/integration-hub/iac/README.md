# Integration Hub PagerDuty infrastructure

This Terraform configuration creates the AWS resources needed by the
PagerDuty Terraform configuration in
`ministryofjustice/integration-hub/terraform/pagerduty`. It does not connect
to PagerDuty itself.

The resources are created only in the `integration-hub-production` workspace.
Plans for development, test and preproduction make no changes. This
configuration has its own state in `modernisation-platform-terraform-state`.

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
`repo:ministryofjustice/integration-hub:ref:refs/heads/main` (apply on merge) or
`repo:ministryofjustice/integration-hub:pull_request` (plan on pull requests).

The role can:

- List the state path, read and write `pagerduty/terraform.tfstate`, and
  read, create and delete its `.tflock` file.
- Use the state key through S3.
- Read the `pagerduty/api-key` secret and decrypt it through Secrets Manager.

Both jobs have these permissions. Neither can delete state or change the token.

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

This deploys the AWS resources only. The PagerDuty Terraform workflows are in
the separate `ministryofjustice/integration-hub` repository and are set up on
their own.

1. Deploy this configuration. After initial setup, an authorised person sets the
   token in `pagerduty/api-key`. Do not put the token in Terraform or GitHub.
2. Set the `PRODUCTION_ACCOUNT_ID` repository secret in `integration-hub`.
   The workflow plans pull requests from branches in that repository and
   applies on pushes to `main`. PR code that runs the plan has access to
   production state and the PagerDuty token before merge.

The backend in the `integration-hub` repository uses
`alias/s3/integration-hub-production-pagerduty-tfstate` with `encrypt = true`,
so no key ARN is passed to `terraform init`.

## Known gaps

- The generated `platform_secrets.tf` reads `environment_management` as an
  ordinary data source, so its value is stored in this configuration's state.
  This is not the PagerDuty token.
- The state bucket has no S3 access logging or lifecycle rule. The team still
  needs to agree how long to retain state.
- Secret rotation is disabled. PagerDuty token rotation is manual.
