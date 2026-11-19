# Integration Hub PagerDuty infrastructure

This Terraform configuration creates the AWS resources needed by the
PagerDuty Terraform configuration in
`ministryofjustice/integration-hub/terraform/pagerduty`. It does not connect
to PagerDuty itself.

The resources are created only in the `integration-hub-production` workspace.
Plans for development, test and preproduction make no changes. This
configuration has its own state in
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
- `/github-actions/integration-hub-pagerduty-plan`

### API key secret

The `pagerduty/api-key` secret is created without a value or a secret
version. It has the tag `credential-expiration=none`. An authorised person
must add the PagerDuty API token after the first apply.

The `pagerduty/api-key-read-only` secret is created the same way, without a
value or version, and uses the same token KMS key. An authorised person must
add a read-only PagerDuty API key. Check its access level in PagerDuty first;
the secret name does not enforce it. Do not reuse the write-capable token.

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
`repo:ministryofjustice/integration-hub:ref:refs/heads/main`.

The role can:

- List, read and write `pagerduty/terraform.tfstate` and its `.tflock` file.
- Use the state key through S3.
- Read the API key secret over TLS and decrypt it through Secrets Manager.

It cannot delete state or write the secret.

### GitHub Actions plan role

The `/github-actions/integration-hub-pagerduty-plan` role is for pull request
plans. It uses the same IAM module version and OIDC provider, but trusts only
the subject `repo:ministryofjustice/integration-hub:environment:pagerduty-production-plan`
with audience `sts.amazonaws.com`, not the plain `pull_request` subject.

The role can:

- Read `pagerduty/terraform.tfstate` and manage its `.tflock` file.
- Use the state key through S3.
- Read `pagerduty/api-key-read-only` over TLS and decrypt it through Secrets Manager.

It cannot write state or read the write-capable `pagerduty/api-key`. Create
the initial state with the apply role first.

Before deploying, create the `pagerduty-production-plan` environment in the
`integration-hub` repository with required reviewers, no self-review and
administrator bypass off. A workflow that names a missing environment creates it unprotected,
and the role trusts that name. Add the deployment branch rule
`refs/pull/*/merge` so `pull_request` jobs can use it. Approved PR code can
read production state and the read-only token, so only approve changes you
trust.

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

This deploys the AWS resources only. The PagerDuty Terraform workflow is in the
separate `ministryofjustice/integration-hub` repository and is set up on its
own.

1. In the `integration-hub` repository, create the `pagerduty-production-plan`
   environment as above.
2. Merge this pull request. The `integration-hub` workflow in this repository
   plans the change and, with the usual approval, applies it to production.
3. After the first apply, an authorised person adds the PagerDuty API token to
   `pagerduty/api-key` and a read-only key to `pagerduty/api-key-read-only`.
   Do not put either in code or Terraform; this configuration does not read or
   store them.
4. In the `integration-hub` repository, add the production account ID as the
   `PRODUCTION_ACCOUNT_ID` secret. The apply job there must run on `main` and
   must not use a GitHub environment, because GitHub sends a different subject
   for those. Anyone who can run a workflow on `main` can assume the apply
   role, so keep `main` protected. The plan job uses the
   `pagerduty-production-plan` environment and the plan role.

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
