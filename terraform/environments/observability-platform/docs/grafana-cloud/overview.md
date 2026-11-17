# Grafana Cloud

`grafana-cloud-stack.tf` creates a new Grafana Cloud stack alongside the existing
Amazon Managed Grafana platform. It does not import or modify the `mojdigital`
test stack or migrate dashboards. Tenants and their AWS accounts, described
below, drive the PDC networks and tokens in `grafana-cloud-pdc-accounts.tf`,
the AWS data sources in `grafana-cloud-data-sources.tf`, the push tokens in
`grafana-cloud-push-accounts.tf` and the shared Metrics, Logs and Traces data
sources in `grafana-cloud-shared-data-sources.tf`.

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
`accesspolicies:read`/`write`/`delete` (PDC networks and their tokens, the push
tokens and the shared data sources' read token are access policies and tokens).
Create the policy in the `prod-gb-south-1` region.
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
validates the configuration. An account with no settings gets a PDC network and
a CloudWatch data source:

```hcl
tenant_configuration = {
  "team-a" = {
    github_team = "team-a" # optional: gives the tenant a Grafana team and folder
    aws_accounts = {
      "team-a-development" = {}
      "team-a-production" = {
        shared_with_tenants = ["team-b"]
        cloudwatch          = { custom_namespaces = ["ECS/ContainerInsights", "CWAgent"] }
        xray                = { enabled = true }
        amazon_prometheus   = { workspace_id = "ws-..." }
        push                = { metrics = true, logs = true, traces = true }
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
| `pdc_enabled` | `true` | PDC network and token for the account. Must match the tenant module's `grafana_cloud.pdc_agent.enabled` |
| `shared_with_tenants` | `[]` | Other tenants whose teams can also query the account's data sources |
| `cloudwatch.enabled` | `true` | `<account>-cloudwatch` data source |
| `cloudwatch.custom_namespaces` | `[]` | Custom metric namespaces, one per item |
| `xray.enabled` | `false` | `<account>-xray` data source. Opt in: Grafana Cloud Tempo is the preferred trace store |
| `amazon_prometheus` | unset | `<account>-amp` data source for the workspace: `workspace_id`, and `region` (default `eu-west-2`) |
| `push.metrics`, `push.logs`, `push.traces` | `false` | The account pushes the signal to Grafana Cloud: its push token can write it, and the shared data source shows the account's data. See [Grafana Cloud Metrics, Logs and Traces](#grafana-cloud-metrics-logs-and-traces) |

The configuration is rejected if an account is listed under more than one
tenant, if `shared_with_tenants` names the owning tenant or a tenant that isn't
in the configuration, if a custom namespace isn't a single CloudWatch namespace,
or if the workspace ID or region is malformed.

## Private Data Source Connect (PDC)

`grafana-cloud-pdc-accounts.tf` creates, for each AWS account in
`grafana-cloud-tenant-environment-configurations.tf` with `pdc_enabled` (default
`true`, matching the tenant module's `grafana_cloud.pdc_agent.enabled`):

- a PDC network and a PDC network token, named
  `<stack slug>-<account name>` and `<stack slug>-<account name>-agent`
- a customer managed KMS key, aliased `alias/grafana-cloud-pdc-<account name>`
- a `grafana-cloud/pdc/<account ID>` secret holding the token, written by Terraform

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
of those tenants has a team, only Admins can query the data source. The GitHub
data source keeps Grafana's default permissions. The shared Metrics, Logs and
Traces data sources also have label-based access control rules: see
[Label-based access control](#label-based-access-control).

## Grafana Cloud Metrics, Logs and Traces

Each stack has one Metrics (Mimir), one Logs (Loki) and one Traces (Tempo)
store, and every tenant account pushes to the same stores. An OpenTelemetry
(OTLP) gateway in the account sends the account's telemetry, with the account ID
in the `cloud.account.id` resource attribute, using a write token from this
environment. Teams query the stores through three shared data sources, whose
label-based access control (LBAC) rules limit each team to the accounts it can
query.

The gateway isn't deployed yet. It will be part of a later tenant module
release.

### Push tokens

`grafana-cloud-push-accounts.tf` creates, for each account that pushes at least
one signal:

- an access policy, `<stack slug>-<account name>-push`, and its token,
  `<stack slug>-<account name>-push-gateway`. The policy can only write the
  signals the account pushes (`metrics:write`, `logs:write` and
  `traces:write`), and only to this environment's stack
- a customer managed KMS key, aliased `alias/grafana-cloud-push-<account name>`
- a `grafana-cloud/push/<account ID>` secret, written by Terraform, holding this
  JSON object:

| Key | Value |
| --- | --- |
| `otlp_endpoint` | The stack's OTLP endpoint. OTLP/HTTP exporters append `/v1/metrics`, `/v1/logs` or `/v1/traces` |
| `username` | The stack ID: the basic auth username |
| `token` | The token: the basic auth password |
| `signals` | The signals the token can write, such as `["logs", "metrics", "traces"]` |

As for PDC, the secret and KMS key policies allow only the account's
`grafana-otlp-gateway-execution` role to read the token. The tenant module must
create the gateway execution role with that name, give it an identity policy
allowing `secretsmanager:GetSecretValue` on the secret and `kms:Decrypt` on the
key, and derive the secret ARN from this account's ID and the tenant account ID.

The tokens don't expire, like the PDC tokens. To rotate one, replace its
`grafana_cloud_access_policy_token.push` resource, then restart the gateway.
The `grafana_cloud_push_accounts` output gives each pushing account's ID,
signals and token secret ARN, keyed by account name.

A write token can't be limited to labels. It can write data with any
`cloud.account.id`, which is what the LBAC rules match. So only the gateway may
hold the token, not applications, and the gateway must set `cloud.account.id`
to its own account ID, overwriting any value that applications send.

### Shared data sources

`grafana-cloud-shared-data-sources.tf` calls
`modules/grafana-cloud/shared-data-sources` once at least one account in the
environment pushes a signal. Until then it creates nothing, so production has no
shared data sources yet.

| Data source | Type | URL |
| --- | --- | --- |
| `shared-metrics` | `prometheus` | The stack's `prometheus_remote_endpoint` |
| `shared-logs` | `loki` | The stack's `logs_url` |
| `shared-traces` | `tempo` | The stack's `traces_url`, followed by `/tempo` |

The UIDs are the same as the names, so the data sources can link to each other.
They use basic auth: the store's user ID, and a token from one read-only access
policy, `<stack slug>-shared-read`, with the `metrics:read`, `logs:read` and
`traces:read` scopes. The policy must not have label selectors, because those
take precedence over LBAC rules.

Spans link to the service's logs for the trace, to the service's metrics, and to
the service graph. Log records link to their traces through the `trace_id`
structured metadata, and metric exemplars through their `trace_id` label.

### Label-based access control

Each shared data source has one `grafana_data_source_config_lbac_rules`
resource, which is authoritative over all of the data source's rules. A team
gets one rule for each account it can query (its tenant's accounts and those
shared with it) that pushes the signal. A team's rules are combined with OR.

| Data source | Rule |
| --- | --- |
| `shared-metrics` | `{ cloud_account_id="<account ID>" }` |
| `shared-logs` | `{ cloud_account_id="<account ID>" }` |
| `shared-traces` | `{ resource.cloud.account.id="<account ID>" }` |

Each data source also has one authoritative `grafana_data_source_permission`,
which grants Query only to the teams that have at least one of those accounts.
It removes Grafana's default Viewer and Editor access. If no team has one, only
Admins can query the data source.

If none of a user's teams has rules on a data source, the user can query all of
its data. So a team with no account pushing the signal gets a rule that matches
no data, `cloud_account_id="none"`, rather than no rules, and Terraform applies
rules before permissions. A team never has Query without rules, and a Query
permission granted by hand can't expose other teams' data.

The rules also apply to Admins in a team with rules, so platform team members
only see their own accounts' data through the shared data sources. Admins who
aren't in such a team, including the Terraform service account, see all of it.
A data source can have roughly 5,000 to 6,000 rules.

### Built-in data sources

Each stack also has built-in data sources for these stores,
`grafanacloud-<stack slug>-prom`, `grafanacloud-<stack slug>-logs` and
`grafanacloud-<stack slug>-traces`, which have no LBAC rules. Every Viewer could
query every account's data through them. So the module looks them up by name and
gives each an authoritative `grafana_data_source_permission` with no grants,
making them admin-only. Grafana Cloud apps that use them, such as Application
Observability, are then only for Admins. Removing the permission resource
doesn't restore other users' access. If a lookup fails, check the names in the
stack's **Connections** > **Data sources** page.

### Before pushing real data

Complete these before any account pushes real data:

- **Promote the account ID label.** Grafana Cloud doesn't turn the OTLP
  `cloud.account.id` resource attribute into a `cloud_account_id` label by
  default, so the metrics and logs rules match nothing until it does: the
  shared data sources fail closed. For Metrics, ask Grafana Support, because
  the self-serve option is experimental. For Logs, add the attribute as an
  index label in the stack's OTLP configuration, within the limit on index
  labels (15 by default). Traces need no change.
- **Change the Tempo redaction mode.** Tempo LBAC is in public preview. By
  default, a query for a trace by ID keeps the spans the user can't see,
  removing their attributes but not their names, IDs, timings or status. Ask
  Grafana Support to use the Spans or Error redaction mode, which removes those
  spans or rejects the query.
- **Confirm traces LBAC is enabled and enforced** on each stack before any
  account in it pushes real traces. Traces LBAC needs Grafana's
  `teamHttpHeadersTempo` feature toggle, which is experimental and off by
  default. If the toggle is off, Grafana may keep the `shared-traces` rules
  without applying them, and every team with Query on `shared-traces` would see
  every account's traces: traces fail open, unlike metrics and logs, which fail
  closed until the label is promoted. In development, step 2 of
  [Testing in development](#testing-in-development) is the definitive check.
  For production, rely on Grafana Support: ask them to confirm, or enable,
  traces LBAC on both the development and production stacks. This can go in
  the same ticket as the redaction mode.
- **Check the built-in data sources** are admin-only after the first apply, and
  stay that way.
- **Check the Grafana Cloud plan** includes team LBAC for Metrics, Logs and
  Traces.
- **Deploy the gateway**, which holds the token and overwrites
  `cloud.account.id`.
- **Get security and data protection impact assessment (DPIA) sign-off** for
  teams sharing the stores.

Metrics that Tempo generates from traces, such as the service graph and span
metrics, have no `cloud_account_id` label. They aren't visible through
`shared-metrics` until it's added as a dimension.

### Changing tenants and teams

- **Removing a tenant, or its `github_team`:** apply this in two steps. First
  remove the tenant's accounts and any `shared_with_tenants` entries naming it,
  so that its team loses Query. Then remove the tenant. Doing both at once
  briefly leaves the team with Query but no rules.
- **New data sources:** Grafana gives Viewers and Editors Query on a new data
  source until its permission applies, a few seconds later. Create the shared
  data sources before real data is pushed, and don't replace them.

### Testing in development

`sprinkler-development` pushes all three signals in development, so the
platform team can test the whole path before the gateway exists:

1. With credentials for the observability-platform-development account, send
   test data with sprinkler's push token, once with sprinkler's account ID and
   once with another account ID. For example, with
   [telemetrygen](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen):

   ```bash
   secret=$(aws secretsmanager get-secret-value --query SecretString --output text \
     --secret-id "grafana-cloud/push/${SPRINKLER_ACCOUNT_ID}")
   otlp=$(jq -r .otlp_endpoint <<<"${secret}" | sed 's|^https://||')
   auth=$(jq -j '"\(.username):\(.token)"' <<<"${secret}" | base64 | tr -d '\n')
   for account_id in "${SPRINKLER_ACCOUNT_ID}" 000000000000; do
     for signal in traces metrics logs; do
       telemetrygen "${signal}" --otlp-http \
         --otlp-endpoint "${otlp%%/*}:443" \
         --otlp-http-url-path "/${otlp#*/}/v1/${signal}" \
         --otlp-header "Authorization=\"Basic ${auth}\"" \
         --otlp-attributes "cloud.account.id=\"${account_id}\""
     done
   done
   ```

   Keep the quotes around the account ID, so that telemetrygen sends it as a
   string, which the rules match.

2. As a member of the `observability-platform` team, check that `shared-traces`
   shows only sprinkler's traces, and the built-in traces data source shows
   both. If `shared-traces` also shows the `000000000000` traces, traces LBAC
   isn't enforced, and no production team may get Query on `shared-traces`
   until it is. `shared-metrics` and `shared-logs` show nothing until the label
   is promoted, and then only sprinkler's data.
3. As a Viewer who isn't in a tenant team, check that you can't query the shared
   or built-in data sources.
4. To check that the token can only write its signals, remove one from
   sprinkler's `push`, apply, and check that pushing it fails.

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
