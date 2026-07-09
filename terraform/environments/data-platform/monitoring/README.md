# Monitoring

Terraform module that deploys Grafana (via Helm) onto EKS and manages, as code:

- **Dashboards** — JSON files under `src/helm/dashboards/`, provisioned into Grafana folders.
- **Alert rules** — generated from a compact "golden signals" definition and across environments, AWS accounts, and resources.

It supports the `development` and `production` environments (`test` and `preproduction` only host the monitored AWS accounts; they don't run their own Grafana stack — see `environment-configuration.tf`).

## List of files

```
environment-configuration.tf   Per-environment settings: which accounts Grafana
                                monitors, which of those accounts get alerts,
                                and which alert groups are enabled per account.

alerting-golden-signals.tf     The alert catalogue: one entry per metric/signal,
                                grouped into named "groups" (e.g. "AI Gateway").

alerting-defaults.tf           Threshold values (warning/critical) referenced
                                by the golden signals above, with optional
                                per-account overrides.

alerting-rules.tf              The engine: expands golden signals into one
                                Grafana alert rule per resource/account/severity,
                                builds the CloudWatch/Prometheus query pipeline,
                                and resolves Slack routing.

alerting.tf                    Terraform resources (grafana_folder,
                                grafana_rule_group) that actually create the
                                alert rules in Grafana from the generated data.

grafana-dashboards.tf           Terraform resources that push the dashboard
src/helm/dashboards/…           JSON files into Grafana folders.

helm-charts.tf                 Deploys the Grafana Helm release itself.
```

Nothing in `alerting-rules.tf` or `alerting.tf` needs to change to add a new alert — those two files are the generic. Day-to-day changes happen in `alerting-golden-signals.tf`, `alerting-defaults.tf`, and `environment-configuration.tf`.

## Adding a new alert or group

### 1. Add a new group

Groups map to a Grafana folder and give the rule group a name suffix. Add an entry to `group_folders` in `alerting-golden-signals.tf`:

```hcl
group_folders = {
  "AI Gateway" = { folder = "internal/compute/ai-gateway", name_suffix = "litellm" }
  "Data Store" = { folder = "internal/data/rds",           name_suffix = "rds" }
}
```

- `folder` — the Grafana folder path the rule group is filed under.
- `name_suffix` — appended to `<env>-` to build the Grafana rule group name (e.g. `development-rds`).

A group only produces alerts once it's also switched on for an account 

### 2. Add a new alert (golden signal)

Add an entry to `alerting_golden_signals` in `alerting-golden-signals.tf`. Each key is the alert's base name (resource identifiers get appended automatically when the rule applies to a list of resources, e.g. per S3
bucket).

> **Write each entry as a single line.** Every existing entry in
> `alerting_golden_signals` (the `litellm_*` rules) is one line, even the
> long Prometheus `expr` ones. Keep new entries on one line too — it makes
> the block scannable as a table (one alert per line) and keeps diffs to a
> single changed/added line when a rule is tweaked. The multi-line HCL below
> is only spaced out for readability in this doc; the "as written" line
> under each example is how it should actually look in the file.

**CloudWatch example** — RDS CPU utilization, one rule per RDS instance:

```hcl
rds_cpu_utilization = {
  group     = "Data Store"
  namespace = "AWS/RDS"
  metric    = "CPUUtilization"
  statistic = "Average"
  type      = "gt"
  dim_key   = "DBInstanceIdentifier"
  warning   = "rds_cpu_warn"
  critical  = "rds_cpu_crit"
}
```

As written in `alerting-golden-signals.tf`:

```hcl
rds_cpu_utilization = { group = "Data Store", namespace = "AWS/RDS", metric = "CPUUtilization", statistic = "Average", type = "gt", dim_key = "DBInstanceIdentifier", warning = "rds_cpu_warn", critical = "rds_cpu_crit" }
```

**Prometheus example** — no CloudWatch dimension, single global rule:

```hcl
litellm_latency_p99 = {
  group           = "AI Gateway"
  datasource_type = "prometheus"
  expr            = "histogram_quantile(0.99, sum(rate(litellm_request_latency_seconds_bucket[5m])) by (le))"
  metric          = "litellm_latency_p99_seconds"
  type            = "gt"
  dim_key         = ""
  warning         = "litellm_latency_p99_warn"
}
```

As written in `alerting-golden-signals.tf`:

```hcl
litellm_latency_p99 = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_request_latency_seconds_bucket[5m])) by (le))", metric = "litellm_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_latency_p99_warn" }
```

**Warning + critical, S3 bucket example** — one rule per bucket in `cfg.s3_buckets`, both severities, single line:

```hcl
s3_bucket_5xx_errors = { group = "Data Store", namespace = "AWS/S3", metric = "5xxErrors", statistic = "Sum", type = "gt", dim_key = "BucketName", warning = "s3_5xx_warn", critical = "s3_5xx_crit" }
```

Then add matching threshold keys to `alert_defaults` in `alerting-defaults.tf`:

```hcl
rds_cpu_warn = 75  # % CPU — warning
rds_cpu_crit = 90  # % CPU — critical
```

A severity (`warning` or `critical`) is only generated if the golden signal sets that key — omit `critical` on a rule to make it warning-only, as `litellm_deployment_state_warning` does.

### 3. Enable the group for an account

Add the group name to `enabled_groups` for the relevant account(s) in `environment-configuration.tf`. Rules are only created for a group/account pair once the group is listed here:

```hcl
alerts_configured_accounts = [
  { name = "data-platform-development", enabled_groups = ["AI Gateway", "Data Store"] },
]
```

This same entry is where every other account-level lives — resourse lists for the `dim_key` fan-out, threshold overrides, Slack routing, disabled rules, and query settings. Every field below is optional; add only what you need. See [Account configuration fields](#account-configuration-fields-alerts_configured_accounts)
for the full reference.

```hcl
alerts_configured_accounts = [
  {
    name           = "data-platform-development"
    enabled_groups = ["AI Gateway", "Data Store"]

    # Resource lists the dim_key fan-out cross-multiplies against
    # (see "Supported dim_key values" below)
    s3_buckets       = ["data-platform-dev-landing", "data-platform-dev-curated"]
    rds_instances    = ["data-platform-dev"]
    cache_clusters   = ["dev"]
    namespaces       = ["cpanel", "airflow"]
    efs_file_systems = ["fs-0123456789abcdef0"]

    # Skip specific rule keys entirely for this account (no rule/uid created)
    disabled_rules = ["rds_cpu_utilization"]

    # Override a threshold key from alert_defaults for this account only
    threshold_overrides = {
      rds_cpu_warn = 85
      rds_cpu_crit = 95
    }

    # Account-wide fallback Slack channel, used when a golden signal has no
    # slack_channel of its own
    slack_channel = "dev-slack"

    # Per-rule, per-severity Slack overrides — the key is the combo_key
    # (rule key plus resource suffix, e.g.
    # "s3_bucket_5xx_errors_data-platform-dev-landing")
    slack_channel_overrides = {
      rds_cpu_utilization  = { critical = "dev-slack-critical" }
      s3_bucket_5xx_errors = { warning = "disabled" } # suppresses the label entirely
    }

    # How often Grafana evaluates rules for this account (defaults to "1m")
    evaluation_interval = "5m"

    # Overrides for the auto-derived datasource UID / region
    prometheus_datasource_uid = "custom-amp-uid"
    aws_region                = "eu-west-2"
  },
]
```


## Golden signal variables

Every key inside `alerting_golden_signals` (in `alerting-golden-signals.tf`) is one of the fields below.

| Field | Required | Description |
|---|---|---|
| `group` | yes | Alert group name. Must match a key in `group_folders`. |
| `namespace` | CloudWatch only | CloudWatch namespace (e.g. `AWS/RDS`). Omit for Prometheus signals. |
| `metric` | yes | CloudWatch metric name, or a short label used as the `metric` alert label for Prometheus signals. |
| `statistic` | CloudWatch only | CloudWatch statistic — `Sum`, `Average`, `Maximum`, `Minimum`, `p99`, etc. |
| `datasource_type` | no | Set to `"prometheus"` to use PromQL instead of CloudWatch. When set, supply `expr` instead of `namespace`/`metric`/`statistic`. |
| `expr` | Prometheus only | PromQL expression. Use the literal token `__NAMESPACES__` where a namespace regex is needed — it's replaced at render time with the account's `namespaces` list joined by `\|`. |
| `type` | yes | Alert logic: `gt` (fire when value > threshold), `lt` (fire when value < threshold), `baseline_gt` (fire when % above hourly baseline), `baseline_lt` (fire when % below hourly baseline). `gt`/`lt` evaluate condition `C`; `baseline_*` evaluate condition `D`. |
| `dim_key` | yes | Primary CloudWatch dimension key. `""` = no dimension filter (a single global rule). Otherwise one of the supported keys below — one alert rule is generated per value in the resolved list, with the value appended as a suffix to the rule name. |
| `dim_key2` | no | Optional second dimension key, always matched against `"*"`. Used for ContainerInsights metrics that need e.g. `{Namespace=cpanel, ClusterName=*}` to get the namespace-level aggregate instead of per-pod series. |
| `match_exact` | no (default `false`) | If `true`, CloudWatch returns only series whose dimension set exactly matches the supplied keys (no extra dimensions). Needed for ContainerInsights cluster-level aggregates to exclude per-pod series. |
| `use_metric_math` | no (default `false`) | If `true`, adds a second CloudWatch query (`A2`) for a capacity/limit metric and computes `$A / $A2 * 100` as `EXPR`. The threshold is then evaluated against that utilisation percentage instead of the raw value from `A`. Requires `capacity_metric`. |
| `capacity_metric` | with `use_metric_math` | CloudWatch metric name used as the denominator (`A2`) in the metric-math expression, e.g. `"PermittedThroughput"`. |
| `capacity_statistic` | no (default `"Minimum"`) | CloudWatch statistic applied to the capacity metric. Only used with `use_metric_math`. |
| `ok_when_nodata` | no (default `false`) | If `true`, sets `noDataState: OK` so the rule resolves to Normal when CloudWatch/Prometheus returns nothing (e.g. zero failed nodes), rather than going to `NoData`. |
| `slack_channel` | no | Slack channel(s) for this signal. Either a string (same channel both severities) or an object `{ warning = "...", critical = "..." }` (omit a key to emit no label for that severity). Resolution order per severity: rule's per-severity key → rule's string value → the account's `slack_channel` default. If nothing resolves, no `slack-channel` label is set and Grafana's catch-all policy handles routing. |
| `warning` | one of `warning`/`critical` required | Key into `alert_defaults` (or an account's `threshold_overrides`) for the warning threshold. Omit to make the rule critical-only. |
| `critical` | one of `warning`/`critical` required | Same, for the critical threshold. Omit to make the rule warning-only. |
| `query_window_seconds` | no (default `300`) | Lookback window, in seconds, for the current-value queries (refs `A`, `A2`, `B`, `C`). |
| `baseline_window_seconds` | no (default `3600`) | Lookback window and CloudWatch period, in seconds, for the baseline pipeline (refs `BASE`, `BASE_R`, `D`). Only relevant for `baseline_gt`/`baseline_lt` types. |

### Supported `dim_key` values

| `dim_key` | Resolves against (per account, in `environment-configuration.tf`) |
|---|---|
| `""` | No dimension filter — a single global aggregate rule. |
| `BucketName` | `cfg.s3_buckets` — list of bucket names |
| `DBInstanceIdentifier` | `cfg.rds_instances` — list of RDS instance IDs |
| `CacheClusterId` | `cfg.cache_clusters` — list of ElastiCache cluster IDs |
| `Namespace` | `cfg.namespaces` — list of k8s namespaces |
| `ClusterName` | `["*"]` — wildcard, all clusters |
| `NodeName` | `["*"]` — wildcard, all nodes |
| `FileSystemId` | `cfg.efs_file_systems` — list of EFS file system IDs |

One Grafana alert rule is created per value in the resolved list, and that value is appended as a suffix to the rule name (e.g.
`s3_bucket_errors_my-bucket-name`).

## Account configuration fields (`alerts_configured_accounts`)

Each entry in `alerts_configured_accounts` (in `environment-configuration.tf`) configures alerting for one monitored AWS account. `name` must match an entry in that environment's `grafana_monitored_accounts`; every other field is optional.

| Field | Required | Default | Description |
|---|---|---|---|
| `name` | yes | — | AWS account name, e.g. `"data-platform-development"`. Must exist in `grafana_monitored_accounts` for the environment. The `data-platform-` prefix is stripped to form `uid` (used in datasource UIDs and folder names) and the key of `grafana_monitored_accounts_by_uid`. |
| `enabled_groups` | no | `[]` (no alerts) | List of group names (keys from `group_folders`) to generate alert rule groups for in this account. A group with no account enabling it produces no rules anywhere. |
| `s3_buckets` | with `BucketName`-dimensioned rules | `[]` | List of S3 bucket names. One rule is generated per bucket for any golden signal with `dim_key = "BucketName"`. |
| `rds_instances` | with `DBInstanceIdentifier`-dimensioned rules | `[]` | List of RDS instance identifiers. One rule per instance for `dim_key = "DBInstanceIdentifier"`. |
| `cache_clusters` | with `CacheClusterId`-dimensioned rules | `[]` | List of ElastiCache cluster IDs. One rule per cluster for `dim_key = "CacheClusterId"`. |
| `namespaces` | with `Namespace`-dimensioned rules | `["cpanel"]` | List of Kubernetes namespaces. One rule per namespace for `dim_key = "Namespace"`; also joined with `\|` to build the `__NAMESPACES__` regex token used in Prometheus `expr` strings. |
| `efs_file_systems` | with `FileSystemId`-dimensioned rules | `[]` | List of EFS file system IDs. One rule per filesystem for `dim_key = "FileSystemId"`. |
| `disabled_rules` | no | `[]` | List of golden-signal rule keys (the keys in `alerting_golden_signals`) to skip entirely for this account — no rule, no Grafana UID, regardless of `enabled_groups`. |
| `threshold_overrides` | no | `{}` | Map of threshold key → value, merged over `alert_defaults` for this account only (`merge(alert_defaults, threshold_overrides)`). Use the same keys referenced by golden signals' `warning`/`critical` fields. |
| `slack_channel` | no | none | Account-wide fallback Slack channel. Used for a rule's severity only when neither the golden signal's own `slack_channel` nor a `slack_channel_overrides` entry resolves one. |
| `slack_channel_overrides` | no | `{}` | Map keyed by `combo_key` (the rule key, plus a resource suffix such as `_<bucket-name>` when the rule is dimensioned) → `{ warning = "...", critical = "..." }`. Takes priority over everything else, including the golden signal's own `slack_channel`. Set a severity's value to `"disabled"` to force no Slack label for that severity (overriding even the account's `slack_channel` fallback). |
| `evaluation_interval` | no | `"1m"` (`local.evaluation_interval`) | How often Grafana evaluates every rule group for this account. Accepts `"30s"`, `"1m"`, `"5m"`, `"2h"`-style duration strings. |
| `prometheus_datasource_uid` | no | `"<uid>-prometheus"` | Grafana datasource UID used for Prometheus (`datasource_type = "prometheus"`) queries. Override if the Amazon Managed Prometheus datasource was provisioned under a different UID. |
| `aws_region` | no | current provider region (`data.aws_region.current.region`) | AWS region passed to CloudWatch queries for this account. Override for accounts monitored cross-region. |

> `s3_buckets`, `rds_instances`, `cache_clusters`, `namespaces`, and
> `efs_file_systems` only matter for golden signals whose `dim_key` matches;
> an account can safely omit any list it doesn't need.

### Examples of individual override fields

**`disabled_rules`** — turn off specific golden signals for one account, even if their group is enabled:

```hcl
disabled_rules = ["rds_cpu_utilization", "litellm_provider_state"]
```

**`threshold_overrides`** — tighten or loosen a threshold for one account only, without touching the shared default in `alert_defaults`:

```hcl
threshold_overrides = {
  rds_cpu_warn = 85
  rds_cpu_crit = 95
}
```

**`slack_channel`** — account-wide fallback channel, used whenever a rule's severity has no more specific channel resolved:

```hcl
slack_channel = "dev-alerts"
```

**`slack_channel_overrides`** — redirect (or silence) one specific rule's severity for this account, keyed by `combo_key` (rule key + resource suffix if the rule is dimensioned):

```hcl
slack_channel_overrides = {
  rds_cpu_utilization                          = { critical = "oncall-critical" }
  s3_bucket_5xx_errors_data-platform-dev-landing = { warning = "disabled" }
}
```

**`evaluation_interval`** — evaluate this account's rules less often than the `1m` default:

```hcl
evaluation_interval = "5m"
```

**`prometheus_datasource_uid` / `aws_region`** — point Prometheus queries at a non-default datasource UID, or run CloudWatch queries against a different region:

```hcl
prometheus_datasource_uid = "custom-amp-uid"
aws_region                = "eu-west-2"
```

## Dashboards

Drop a dashboard JSON into the relevant subdirectory of `src/helm/dashboards/` (`platform`, `kubernetes`, `networking`, or
`databases`) and it's provisioned into the matching Grafana folder automaticaly. To add a new folder, add an entry to
`grafana_dashboard_folders` in `locals.tf` and create the matching subdirectory.

Dashboards (and alert rules) are only pushed to Grafana once `grafana_dashboards_enabled` is `true` for the environment and a valid
Grafana service-account token has been populated in Secrets Manager — see the comments in `locals.tf` and `environment-configuration.tf`.
