locals {
  # ---------------------------------------------------------------------------
  # group_folders — maps each alert group to its Grafana folder path and
  # the suffix used when naming the rule group in the YAML output.
  # ---------------------------------------------------------------------------
  group_folders = {
    "AI Gateway" = { folder = "internal/compute/ai-gateway", name_suffix = "litellm" }
  }

  # ---------------------------------------------------------------------------
  # golden_signals — one entry per metric to alert on.
  #
  # Fields:
  #   group          = alert group name (must match a key in group_folders above)
  #   namespace      = CloudWatch namespace (omit for Prometheus signals)
  #   metric         = CloudWatch metric name / short label for Prometheus signals
  #   statistic      = CloudWatch statistic (Sum, Average, Maximum, Minimum, p99 …)
  #   datasource_type = (optional) "prometheus" to use PromQL instead of CloudWatch.
  #                     When set, supply `expr` instead of namespace/metric/statistic.
  #   expr           = PromQL expression (datasource_type = "prometheus" only).
  #                    Use __NAMESPACES__ as a token where a namespace regex is needed;
  #                    it is replaced at render time with cfg.namespaces joined by "|".
  #   type           = alert logic:
  #                      gt          → fire when value > threshold         (condition C)
  #                      lt          → fire when value < threshold         (condition C)
  #                      baseline_gt → fire when % above hourly baseline   (condition D)
  #                      baseline_lt → fire when % below hourly baseline   (condition D)
  #   dim_key        = primary CloudWatch dimension key ("" = no dimension filter)
  #                    Supported keys and the environment_configurations field they
  #                    resolve against at render time:
  #                      ""                     → no dimension filter (global aggregate)
  #                      "BucketName"           → cfg.s3_buckets        (list of bucket names)
  #                      "DBInstanceIdentifier" → cfg.rds_instances     (list of RDS instance IDs)
  #                      "CacheClusterId"       → cfg.cache_clusters    (list of ElastiCache
  #                                               cluster IDs, e.g. ["dev", "prod"])
  #                      "Namespace"            → cfg.namespaces        (list of k8s namespaces)
  #                      "ClusterName"          → ["*"]                 (wildcard — all clusters)
  #                      "NodeName"             → ["*"]                 (wildcard — all nodes)
  #                      "FileSystemId"         → cfg.efs_file_systems  (list of EFS file system IDs)
  #                    One alert rule is generated per value in the resolved list;
  #                    the value is appended as a suffix to the rule name.
  #   dim_key2       = optional second dimension key; always matched with value "*"
  #                    used for ContainerInsights metrics that need e.g.
  #                    {Namespace=cpanel, ClusterName=*} to return the
  #                    namespace-level aggregate instead of per-pod series
  #   match_exact    = (optional, default: false)
  #                    if true, CloudWatch returns only series whose dimension set
  #                    exactly matches the supplied keys (no extra dimensions).
  #                    Required for ContainerInsights cluster-level aggregates to
  #                    exclude per-pod series that carry extra dimensions (PodName etc)
  #   use_metric_math = (optional, default: false)
  #                    if true, emits a second CloudWatch query (refId "A2") for a
  #                    capacity/limit metric and computes "$A / $A2 * 100" via a math
  #                    expression (refId "EXPR"). The reduce step (B) then operates on
  #                    EXPR rather than A, so the threshold is evaluated against a
  #                    utilisation percentage rather than a raw value.
  #                    Requires capacity_metric (and optionally capacity_statistic).
  #   capacity_metric = CloudWatch metric name for the capacity/limit series used as
  #                    the denominator in the metric math expression (A2).
  #                    Only used when use_metric_math = true.
  #                    Example: "PermittedThroughput"
  #   capacity_statistic = CloudWatch statistic to apply to the capacity metric.
  #                    Defaults to "Minimum" when omitted.
  #                    Only used when use_metric_math = true.
  #   ok_when_nodata = (optional, default: false)
  #                    if true, sets noDataState: OK so rules resolve to Normal
  #                    when CloudWatch emits nothing (e.g. zero failed nodes)
  #   slack_channel  = (optional) Slack channel to route this signal's alerts.
  #                    Two forms accepted:
  #                      a) string — same channel for both severities
  #                         slack_channel = "dev-slack"
  #                      b) object — different channel per severity;
  #                         omit a key to emit no label for that severity
  #                         slack_channel = { warning = "dev-slack", critical = "dev-slack-critical" }
  #                    Resolution order per severity (first non-null wins):
  #                      1. per-severity key on this field  (e.g. .critical)
  #                      2. string value on this field
  #                      3. slack_channel in environment_configurations  (env default)
  #                    If none of the above is set the label is omitted entirely
  #                    and Grafana's root / catch-all policy handles the alert.
  #   warning        = key in locals.defaults (or threshold_overrides) for warning level
  #   critical       = key in locals.defaults (or threshold_overrides) for critical level
  # ---------------------------------------------------------------------------
  alerting_golden_signals = {

    # ── AI Gateway (LiteLLM) ──────────────────────────────────────────────────
    litellm_deployment_state = { group = "AI Gateway", datasource_type = "prometheus", expr = "(sum by (litellm_model_name, requested_model) (rate(litellm_deployment_failure_responses_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])) or (sum by (litellm_model_name, requested_model) (rate(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])) * 0)) / sum by (litellm_model_name, requested_model) (rate(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])) * 100", metric = "litellm_deployment_health_check_failure_rate_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_deployment_state_warn", critical = "litellm_deployment_state_crit" }
    litellm_provider_state   = { group = "AI Gateway", datasource_type = "prometheus", expr = "litellm_provider_health_status{container=\"litellm\",api_provider=\"bedrock\"}", metric = "litellm_provider_health_status", type = "eq", dim_key = "", ok_when_nodata = true, warning = "litellm_provider_state_warn", critical = "litellm_provider_state_crit" }

    litellm_deployment_state_admin = { group = "AI Gateway", datasource_type = "prometheus", expr = "(sum by (litellm_model_name, requested_model) (rate(litellm_deployment_failure_responses_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm-admin\"}[5m])) or (sum by (litellm_model_name, requested_model) (rate(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm-admin\"}[5m])) * 0)) / sum by (litellm_model_name, requested_model) (rate(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm-admin\"}[5m])) * 100", metric = "litellm_deployment_health_check_failure_rate_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_deployment_state_admin_warn", critical = "litellm_deployment_state_admin_crit" }
    litellm_provider_state_admin   = { group = "AI Gateway", datasource_type = "prometheus", expr = "litellm_provider_health_status{container=\"litellm-admin\",api_provider=\"bedrock\"}", metric = "litellm_provider_health_status", type = "eq", dim_key = "", ok_when_nodata = true, warning = "litellm_provider_state_admin_warn", critical = "litellm_provider_state_admin_crit" }

  }
}