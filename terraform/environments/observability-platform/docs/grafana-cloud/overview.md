# Grafana Cloud

`grafana-cloud-stack.tf` creates a new Grafana Cloud stack alongside the existing
Amazon Managed Grafana platform. It does not import or modify the `mojdigital`
test stack or migrate dashboards. Tenants and their AWS accounts, described
below, drive the PDC networks and tokens in `grafana-cloud-pdc-accounts.tf` and
the AWS data sources in `grafana-cloud-data-sources.tf`.

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
set an expiry, and rotate before expiry. The
`grafana-cloud/admin-user-details` secret holds the admin username and
password as a JSON object (`{"username": "...", "password": "..."}`). It is
unrelated and is not read by Terraform.

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
Cloud account resources, such as the stack, plugins and PDC networks, explicitly
use `provider = grafana.cloud`. Resources inside the stack, such as SSO, teams,
folders and data sources, use `provider = grafana.stack`, authenticated with the
stack's Terraform service account. Do not repoint the default provider or
existing resources.

Stack destruction and replacement are blocked by `prevent_destroy`, including
the existing workflow's development destroy action. Any intentional stack
deletion requires an explicitly reviewed change to this protection.

## Tenant configuration

`grafana-cloud-tenant-environment-configurations.tf` lists each environment's
tenants and the AWS accounts they own, keyed by account name. The
`modules/grafana-cloud/tenant-configuration` module applies the defaults and
validates the configuration. An account with no settings gets a CloudWatch data
source. PDC is opt-in, for accounts with private data sources to query:

```hcl
tenant_configuration = {
  "team-a" = {
    github_team = "team-a" # optional: gives the tenant a Grafana team and folder
    aws_accounts = {
      "team-a-development" = {}
      "team-a-production" = {
        pdc_enabled         = true # also set grafana_cloud.pdc_agent.enabled in the tenant module
        shared_with_tenants = ["team-b"]
        cloudwatch          = { custom_namespaces = ["ECS/ContainerInsights", "CWAgent"] }
        xray                = { enabled = true }
        amazon_prometheus   = { workspace_id = "ws-..." }
      }
    }
  }
  "team-b" = {
    github_team = "team-b"
  }
}
```

| Account setting | Default | Effect |
| --- | --- | --- |
| `pdc_enabled` | `false` | Opt in to a PDC network and token for the account, for private data sources. Must match the tenant module's `grafana_cloud.pdc_agent.enabled` |
| `shared_with_tenants` | `[]` | Other tenants whose teams can also query the account's data sources |
| `cloudwatch.enabled` | `true` | `<account>-cloudwatch` data source |
| `cloudwatch.custom_namespaces` | `[]` | Custom metric namespaces, one per item |
| `xray.enabled` | `false` | `<account>-xray` data source. Opt in: Grafana Cloud Tempo is the preferred trace store |
| `amazon_prometheus` | unset | `<account>-amp` data source for the workspace: `workspace_id`, and `region` (default `eu-west-2`) |

The configuration is rejected if an account is listed under more than one
tenant, if `shared_with_tenants` names the owning tenant or a tenant that isn't
in the configuration, if a custom namespace isn't a single CloudWatch namespace,
or if the workspace ID or region is malformed.

## Private Data Source Connect (PDC)

`grafana-cloud-pdc-accounts.tf` creates, for each AWS account in
`grafana-cloud-tenant-environment-configurations.tf` with `pdc_enabled = true`
(opt-in, matching the tenant module's `grafana_cloud.pdc_agent.enabled`):

- a PDC network named `<stack slug>-<account name>`
- a customer managed KMS key, aliased `alias/grafana-cloud-pdc-<account name>`
- a `grafana-cloud/pdc/<account ID>` secret; Terraform owns the metadata, not the token value

Networks are per account, not per tenant. PDC load-balances across every agent in
a network, so every agent must reach the same targets, and a tenant's accounts
sit in different VPCs. An account can belong to only one tenant.

The agents run in the tenant accounts and are deployed by the tenant module, which
derives the secret ARN from this account's ID and the tenant account ID, so the
secret name must not change. The secret and KMS key policies allow only that
account's `grafana-pdc-agent-execution` role to read the token. The tenant module
also gives that role an identity policy allowing `secretsmanager:GetSecretValue`
on the secret and `kms:Decrypt` on the key. Restart the agent service after the
token changes, because ECS reads the secret at task start.

The `grafana_cloud_pdc_accounts` output gives each account's ID, PDC network ID
and token secret ARN, keyed by account name.

PDC agents are not deployed from this environment. The tenant module provides them,
together with the networking for each shared VPC.

Sprinkler development rotates automatically. Cooker development has a working
token: the next reviewed handoff forgets its legacy token/version without
revoking it and starts its own 90-day rotation. Neither account uses bootstrap.
For a brand-new opt-in, the central apply must first issue `AWSCURRENT` through
the bootstrap-capable Lambda; the tenant then deploys its existing agent module.
No team member supplies a token. Development configures alpha.6 for
`example-development` and Cloud Platform batch 1
(`cloud-platform-{development,preproduction,nonlive,live}`). After bootstrap,
an hourly readiness check enrols each secret in 90-day rotation only when stable
ECS agents are connected to that account's Grafana network. The eight Container
Platform accounts join the `cloud-platform` tenant in later batches.
Production has no opt-ins or enrolment ticks. See the [PDC rollout runbook](pdc-token-rotation.md).

Grafana Cloud management API calls, browser access and alert notifications
go over public HTTPS.

## AWS data sources

`grafana-cloud-data-sources.tf` calls `modules/grafana-cloud/aws-account-data-sources`
for each account in the tenant configuration, creating the data sources that
the account enables:

| Data source | Type | Plugin |
| --- | --- | --- |
| `<account>-cloudwatch` | `cloudwatch` | Core |
| `<account>-xray` | `grafana-x-ray-datasource` (AWS Application Signals) | Installed when an account enables X-Ray |
| `<account>-amp` | `grafana-amazonprometheus-datasource` (Amazon Managed Service for Prometheus) | Installed when an account sets `amazon_prometheus` |

The names match the Amazon Managed Grafana data sources, so dashboards can move
by name. Grafana generates the UIDs. The data sources are keyed by account, so
moving an account to another tenant only changes who can query them. Plugin
versions are pinned in `grafana-cloud-data-sources.tf`.

The data sources use Grafana Assume Role. Grafana Cloud's AWS account
(`008923505280`) assumes the account's `grafana-cloud` role, which the tenant
module creates with `CloudWatchReadOnlyAccess`, `AWSXrayReadOnlyAccess` and
`AmazonPrometheusQueryAccess`. The external ID is this environment's stack ID.
Grafana sets it, and it can't be configured. The data sources set
`usePerDatasourceExternalId`, or `sigV4UsePerDatasourceExternalId` for Amazon
Managed Service for Prometheus, to `false`. This stops Grafana generating an
external ID per data source, which the role wouldn't trust.

The CloudWatch data source links trace IDs in logs to the account's X-Ray data
source, when there is one. Amazon Managed Service for Prometheus uses its own
plugin, which signs requests with SigV4, because SigV4 in the core Prometheus
data source is deprecated.

These are AWS APIs, not services in the VPC, so the data sources don't use PDC.

### Observability Platform accounts

`observability-platform.tf` still calls the tenant module at version 1.2.0. The
version that creates the `grafana-cloud` role needs AWS provider 6, and this
environment uses 5. So the Observability Platform accounts have no
`grafana-cloud` role, and the development configuration sets
`cloudwatch = { enabled = false }` for `observability-platform-development`.
Turn its data sources on when that module call is upgraded.

## Teams, permissions and sharing

`grafana-cloud-sso.tf` creates a Grafana team and folder for each tenant with a
`github_team`, synced from that GitHub team. The `team_uid` output of
`modules/grafana-cloud/team` identifies the team in label-based access control
rules.

Each AWS data source has one `grafana_data_source_permission`, which grants
Query to the owning tenant's team and to the teams of the tenants in
`shared_with_tenants`. It is authoritative: it removes Grafana's default Viewer
and Editor access, so no other users can query the data source. Admins keep
access, including the platform team and the Terraform service account. If none
of those tenants has a team, only Admins and any matching platform
team can query the data source.

In development and production, GitHub SSO also admits the Ministry of Justice
`modernisation-platform` and `cloud-platform` GitHub teams. They have no basic
Grafana role (so no inherited Viewer access to Grafana Cloud's preconfigured
data sources), and get the Explorer role to open Explore and Drilldown.
`observability-platform` membership still takes precedence and grants Admin.

The two teams can query the shared `ministryofjustice-github` data source and
the AWS data sources for already-onboarded accounts whose canonical
`modernisation-platform/environments/<stem>.json` declares that account:

| GitHub team | `.tags.application` |
| --- | --- |
| `modernisation-platform` | exactly `modernisation-platform` |
| `cloud-platform` | exactly `cloud-platform`, or starts with `container-platform-` |

Terraform reads only the definitions needed for configured accounts, takes
account names from the filename and `.environments[].name`, and grants nothing
for missing or unmatched ownership. The match changes permissions at the next
Terraform reconciliation; it does not create data sources or onboard accounts.
Existing AWS tenant grants and sharing still apply, and configured tenant teams
retain Query on the shared GitHub source. GitHub queries use the stack's shared
GitHub App installation; Grafana permissions do not filter results by the
signed-in user's GitHub repository access. Production currently has no onboarded
AWS accounts; the two teams can query the GitHub source but no AWS sources.
Managing the GitHub source's permissions removes its default Viewer and Editor
grants in both stacks; Admins retain access.

## CloudWatch (Grafana Assume Role)

`grafana-cloud-cloudwatch.tf` creates the `grafana-cloud-cloudwatch` IAM role
with `CloudWatchReadOnlyAccess`. Grafana Cloud's AWS account (`008923505280`)
can assume it only with this environment's stack ID as the external ID. This
pilot role is in the Observability Platform account only. The AWS data sources
above don't use it. Retire it once this account has the tenant module's
`grafana-cloud` role.

CloudWatch is an AWS API, not a service in the VPC, so CloudWatch data sources
don't use PDC. In the data source, set **Authentication Provider** to
**Grafana Assume Role**, **Assume Role ARN** to the
`grafana_cloud_cloudwatch_role_arn` output, and **Default Region** to
`eu-west-2`. Leave **Private data source connect** unset.
