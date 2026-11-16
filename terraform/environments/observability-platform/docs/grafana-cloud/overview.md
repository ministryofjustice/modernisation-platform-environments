# Grafana Cloud

`grafana-cloud-stack.tf` creates a new Grafana Cloud stack alongside the existing
Amazon Managed Grafana platform. It does not import or modify the `mojdigital`
test stack, migrate dashboards, or configure data sources. PDC networks and
tokens are in `grafana-cloud-pdc-tenants.tf`, described below.

| Terraform workspace | AWS account | Grafana Cloud stack |
| --- | --- | --- |
| `observability-platform-development` | observability-platform-development | `mojobservabilitydevelopment` |
| `observability-platform-production` | observability-platform-production | `mojobservabilityproduction` |

Both stacks use Grafana region `prod-gb-south-1`, hosted on AWS London
(`eu-west-2`). Grafana region slugs are not AWS region names.
Stack names must be globally available.

## Credentials

Create a Grafana Cloud access policy token in the intended Grafana Cloud
organisation with `stacks:read`, `stacks:write`, and `stacks:delete` scopes,
plus `stack-plugins:read`/`write`, `stack-service-accounts:read`/`write` and
`accesspolicies:read`/`write`/`delete` (PDC networks and their tokens are access
policies). Create the policy in the `prod-gb-south-1` region.
Its realm must permit organisation-level stack creation, rather than only
access to an existing stack. The organisation associated with this token
determines where the new stacks are created; the AWS account does not.

Terraform creates the empty secret `grafana-cloud/terraform-access-policy-token`
(`secrets.tf`) in each account and reads it in `data.tf`. Populate its value
manually, as with the other Grafana secrets: the raw token as the secret
string, not a JSON object. Use separate tokens for development and production,
set an expiry, and rotate before expiry. The existing
`grafana/grafana-cloud-user` and `grafana/grafana-cloud-password` secrets are
unrelated and are not reused.

Secret values read by Terraform are stored in state and may be present in
saved plans: restrict access to both and to the state backend.

## First deployment order

The data lookup fails if the secret has no value, so deploy in stages:

1. Apply the `secrets.tf` resource only, creating the empty secret in both accounts.
2. Populate the token value in each account.
3. Apply the `data.tf` lookup, provider alias, and `grafana-cloud-stack.tf` stack.

Alternatively, create and populate the secret manually first, then
`terraform import` the `aws_secretsmanager_secret` resource.

## Deployment and existing resources

The existing `.github/workflows/observability-platform.yml` workflow covers
these files and selects the corresponding account and Terraform workspace.
No new workflow or backend is needed. Review plans for both environments
before applying; the new resources must not replace existing Amazon Managed
Grafana resources.

The default `grafana` provider still targets Amazon Managed Grafana.
Cloud account resources explicitly use `provider = grafana.cloud`.
Future dashboards, folders, and data sources in Grafana Cloud need a separate
stack-level provider alias, authenticated with a service-account token for
that Cloud stack. Do not repoint the default provider or existing resources.

Stack destruction and replacement are blocked by `prevent_destroy`, including
the existing workflow's development destroy action. Any intentional stack
deletion requires an explicitly reviewed change to this protection.

## Private Data Source Connect (PDC)

`grafana-cloud-pdc-tenants.tf` creates, for each tenant in
`grafana-cloud-tenant-environment-configurations.tf` with `pdc_enabled = true`
on at least one account:

- a PDC network and a PDC network token
- a customer managed KMS key
- a `grafana-cloud/pdc/<tenant>` secret holding the token, written by Terraform

The agents run in the tenant accounts and are deployed by the tenant module. The
secret and KMS key policies allow only the `grafana-pdc-agent-execution` role in
the tenant's accounts to read the token. The tenant module must also give that role
an identity policy allowing `secretsmanager:GetSecretValue` on the secret and
`kms:Decrypt` on the key, and reference the secret by its full ARN. Restart the agent
service after the token changes, because ECS reads the secret at task start.

The `grafana_cloud_pdc_tenants` output gives each tenant's PDC network ID and token
secret ARN to pass to the tenant module.

PDC agents are not deployed from this environment. The tenant module provides them,
together with the networking for each shared VPC.

Grafana Cloud management API calls, browser access and alert notifications
go over public HTTPS.

## CloudWatch (Grafana Assume Role)

`grafana-cloud-cloudwatch.tf` creates the `grafana-cloud-cloudwatch` IAM role
with `CloudWatchReadOnlyAccess`. Grafana Cloud's AWS account (`008923505280`)
can assume it only with this environment's stack ID as the external ID.

CloudWatch is an AWS API, not a service in the VPC, so CloudWatch data sources
don't use PDC. In the data source, set **Authentication Provider** to
**Grafana Assume Role**, **Assume Role ARN** to the
`grafana_cloud_cloudwatch_role_arn` output, and **Default Region** to
`eu-west-2`. Leave **Private data source connect** unset.
