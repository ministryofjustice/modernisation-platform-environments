locals {
  # ---------------------------------------------------------------------------
  # group_folders — maps each alert group or component to its Grafana folder path and
  # the suffix used when naming the rule group in the YAML output.
  # ---------------------------------------------------------------------------
  group_folders = {
    "AI Gateway" = { folder = "internal/compute/ai-gateway", name_suffix = "litellm" }
  }

  # ---------------------------------------------------------------------------
  # golden_signals — one entry per metric to alert on.
  #
  # Fields:
  #   group          = alert group or component name (must match a key in group_folders above)
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
  #   query_window_seconds    = (optional, default: 300) lookback window for the
  #                              current-value queries (Refs A, A2, B, C)
  #   baseline_window_seconds = (optional, default: 3600) lookback window and
  #                              CloudWatch period for the baseline pipeline
  #                              (Refs BASE, BASE_R, D)
  # ---------------------------------------------------------------------------
  alerting_golden_signals = {
    # -------------------------------------------------------------------------
    # AI Gateway Alerts
    # -------------------------------------------------------------------------
    # ── Deployment Health Check ─────────────────────────────────────────────
    litellm_deployment_state_warning     = { group = "AI Gateway", datasource_type = "prometheus", expr = "(sum by (litellm_model_name, requested_model) (increase(litellm_deployment_failure_responses_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])) or (sum by (litellm_model_name, requested_model) (increase(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])) * 0)) / clamp_min(sum by (litellm_model_name, requested_model) (increase(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])), 1) * 100", metric = "litellm_deployment_health_check_failure_rate_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_deployment_state_warn" }
    litellm_deployment_state_critical    = { group = "AI Gateway", datasource_type = "prometheus", expr = "((count((((sum by (litellm_model_name, requested_model) (increase(litellm_deployment_failure_responses_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m]))) / clamp_min(sum by (litellm_model_name, requested_model) (increase(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m])), 1)) > 0))) or vector(0)) / clamp_min((count(sum by (litellm_model_name, requested_model) (increase(litellm_deployment_total_requests_total{api_key_alias=\"litellm-internal-health-check\",container=\"litellm\"}[5m]))) or vector(0)), 1) * 100", metric = "litellm_deployment_models_failing_pct", type = "gt", dim_key = "", ok_when_nodata = true, critical = "litellm_deployment_state_crit" }
    litellm_provider_state               = { group = "AI Gateway", datasource_type = "prometheus", expr = "(count by (api_provider) (litellm_provider_health_status{container=\"litellm\"} == 0) or (count by (api_provider) (litellm_provider_health_status{container=\"litellm\"}) * 0)) / clamp_min(count by (api_provider) (litellm_provider_health_status{container=\"litellm\"}), 1) * 100", metric = "litellm_provider_models_failing_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_provider_state_warn", critical = "litellm_provider_state_crit" }
    litellm_model_no_healthy_deployments = { group = "AI Gateway", datasource_type = "prometheus", expr = "count by (litellm_model_name) (litellm_deployment_cooled_down_total{container=\"litellm\"} > 0) - count by (litellm_model_name) (litellm_deployment_total_requests_total{container=\"litellm\"} offset 5m > 0)", metric = "litellm_model_deployments_unhealthy_delta", type = "gt", dim_key = "", ok_when_nodata = true, critical = "litellm_model_no_healthy_deployments_crit" }

    # ── Proxy Errors & Traffic ──────────────────────────────────────────────
    litellm_proxy_failed_requests          = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum(increase(litellm_proxy_failed_requests_metric_total{container=\"litellm\"}[5m])) / clamp_min(sum(increase(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m])), 1) * 100", metric = "litellm_proxy_failed_requests_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_proxy_failed_requests_warn", critical = "litellm_proxy_failed_requests_crit" }
    litellm_proxy_failed_requests_by_model = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum by (litellm_model_name, api_provider) (increase(litellm_proxy_failed_requests_metric_total{container=\"litellm\"}[5m])) / clamp_min(sum by (litellm_model_name, api_provider) (increase(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m])), 1) * 100", metric = "litellm_proxy_failed_requests_by_model_pct", type = "gt", dim_key = "", ok_when_nodata = true, critical = "litellm_proxy_failed_requests_by_model_crit" }
    litellm_proxy_traffic_drop             = { group = "AI Gateway", datasource_type = "prometheus", expr = "(sum(rate(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m])) - sum(rate(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m] offset 1h))) / clamp_min(sum(rate(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m] offset 1h)), 1) * 100", metric = "litellm_proxy_traffic_pct_change_vs_1h_ago", type = "lt", dim_key = "", ok_when_nodata = false, warning = "litellm_proxy_traffic_baseline_warn", critical = "litellm_proxy_traffic_baseline_crit" }
    litellm_proxy_zero_traffic             = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum(rate(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m]))", metric = "litellm_proxy_requests_per_sec", type = "lt", dim_key = "", ok_when_nodata = false, critical = "litellm_proxy_zero_traffic_crit" }
    litellm_proxy_rate_limited_requests    = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum(increase(litellm_proxy_total_requests_metric_total{container=\"litellm\", status_code=\"429\"}[5m])) / clamp_min(sum(increase(litellm_proxy_total_requests_metric_total{container=\"litellm\"}[5m])), 1) * 100", metric = "litellm_proxy_429_pct", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_proxy_429_pct_warn" }
    litellm_callback_logging_failures      = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum by (callback_name) (increase(litellm_callback_logging_failures_metric_total{container=\"litellm\"}[5m]))", metric = "litellm_callback_logging_failures_count", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_callback_logging_failures_warn", critical = "litellm_callback_logging_failures_crit" }

    # ── Latency ───────────────────────────────────────────-───────────────────
    litellm_proxy_request_latency_p99               = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_request_total_latency_metric_bucket{container=\"litellm\"}[30m])) by (le))", metric = "litellm_request_total_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_proxy_latency_p99_warn", critical = "litellm_proxy_latency_p99_crit" }
    litellm_llm_api_latency_p99                     = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_llm_api_latency_metric_bucket{container=\"litellm\"}[5m])) by (le))", metric = "litellm_llm_api_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_llm_api_latency_p99_warn", critical = "litellm_llm_api_latency_p99_crit" }
    litellm_ttft_p99                                = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_time_to_first_token_metric_bucket{container=\"litellm\"}[5m])) by (le))", metric = "litellm_ttft_p99_seconds", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_ttft_p99_warn", critical = "litellm_ttft_p99_crit" }
    litellm_overhead_latency_p99                    = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_overhead_latency_metric_bucket{container=\"litellm\"}[5m])) by (le))", metric = "litellm_overhead_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_overhead_latency_p99_warn", critical = "litellm_overhead_latency_p99_crit" }
    litellm_deployment_latency_per_output_token_p99 = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_deployment_latency_per_output_token_bucket{container=\"litellm\"}[5m])) by (le, litellm_model_name))", metric = "litellm_deployment_latency_per_output_token_p99_seconds", type = "gt", dim_key = "", warning = "litellm_deployment_latency_per_token_warn", critical = "litellm_deployment_latency_per_token_crit" }
    litellm_in_flight_requests                      = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum(litellm_in_flight_requests{container=\"litellm\"})", metric = "litellm_in_flight_requests_count", type = "gt", dim_key = "", warning = "litellm_in_flight_requests_warn", critical = "litellm_in_flight_requests_crit" }

    # ── Deployment Resilience (Cooldowns & Fallbacks) ───────────────────────
    litellm_deployment_cooled_down_events = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum by (litellm_model_name) (increase(litellm_deployment_cooled_down_total{container=\"litellm\"}[5m]))", metric = "litellm_deployment_cooldown_count", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_cooldown_events_warn", critical = "litellm_cooldown_events_crit" }
    litellm_deployment_failed_fallbacks   = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum by (requested_model, fallback_model) (increase(litellm_deployment_failed_fallbacks_total{container=\"litellm\"}[5m]))", metric = "litellm_deployment_failed_fallbacks_count", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_failed_fallbacks_warn", critical = "litellm_failed_fallbacks_crit" }

    # ── Rate-Limit Headroom (LLM API provider) ──────────────────────────────
    litellm_remaining_requests_low = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (litellm_model_name, api_provider) (litellm_remaining_requests_metric{container=\"litellm\"})", metric = "litellm_remaining_requests", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_remaining_requests_warn", critical = "litellm_remaining_requests_crit" }
    litellm_remaining_tokens_low   = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (litellm_model_name, api_provider) (litellm_remaining_tokens_metric{container=\"litellm\"})", metric = "litellm_remaining_tokens", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_remaining_tokens_warn", critical = "litellm_remaining_tokens_crit" }

    # ──  Rate-Limit Headroom (per virtual key, model-specific) ───────────────
    litellm_api_key_remaining_requests_low = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (api_key_alias, model) (litellm_remaining_api_key_requests_for_model{container=\"litellm\"})", metric = "litellm_api_key_remaining_requests", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_api_key_remaining_requests_warn", critical = "litellm_api_key_remaining_requests_crit" }
    litellm_api_key_remaining_tokens_low   = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (api_key_alias, model) (litellm_remaining_api_key_tokens_for_model{container=\"litellm\"})", metric = "litellm_api_key_remaining_tokens", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_api_key_remaining_tokens_warn", critical = "litellm_api_key_remaining_tokens_crit" }

    # ── Budget (GBP remaining) ───────────────────────────────────────────────
    litellm_team_budget_remaining    = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (team_alias) (litellm_remaining_team_budget_metric{container=\"litellm\"})", metric = "litellm_team_budget_remaining_gbp", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_team_budget_remaining_warn", critical = "litellm_team_budget_remaining_crit" }
    litellm_api_key_budget_remaining = { group = "AI Gateway", datasource_type = "prometheus", expr = "min by (api_key_alias) (litellm_remaining_api_key_budget_metric{container=\"litellm\"})", metric = "litellm_api_key_budget_remaining_gbp", type = "lt", dim_key = "", ok_when_nodata = true, warning = "litellm_api_key_budget_remaining_warn", critical = "litellm_api_key_budget_remaining_crit" }

    # ── Redis ────────────────────────────────────────────────────────────────
    litellm_redis_failure_rate = { group = "AI Gateway", datasource_type = "prometheus", expr = "sum(increase(litellm_redis_failed_requests_total{container=\"litellm\"}[5m]))", metric = "litellm_redis_fails_count", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_redis_failure_rate_warn", critical = "litellm_redis_failure_rate_crit" }
    litellm_redis_latency_p99  = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_redis_latency_bucket{container=\"litellm\"}[5m])) by (le))", metric = "litellm_redis_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_redis_latency_p99_warn", critical = "litellm_redis_latency_p99_crit" }

    # ── Internal Self Latency ───────────────────────────────────────────────
    litellm_self_latency_p99 = { group = "AI Gateway", datasource_type = "prometheus", expr = "histogram_quantile(0.99, sum(rate(litellm_self_latency_bucket{container=\"litellm\"}[5m])) by (le))", metric = "litellm_self_latency_p99_seconds", type = "gt", dim_key = "", warning = "litellm_self_latency_p99_warn", critical = "litellm_self_latency_p99_crit" }

    # ── Spend Queue Backpressure (DB Transaction Queue Health) ──────────────
    litellm_redis_spend_update_queue_size           = { group = "AI Gateway", datasource_type = "prometheus", expr = "max(litellm_redis_spend_update_queue_size{container=\"litellm\"})", metric = "litellm_redis_spend_update_queue_depth", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_redis_spend_queue_warn", critical = "litellm_redis_spend_queue_crit" }
    litellm_redis_daily_spend_update_queue_size     = { group = "AI Gateway", datasource_type = "prometheus", expr = "max(litellm_redis_daily_spend_update_queue_size{container=\"litellm\"})", metric = "litellm_redis_daily_spend_update_queue_depth", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_redis_daily_spend_queue_warn", critical = "litellm_redis_daily_spend_queue_crit" }
    litellm_in_memory_spend_update_queue_size       = { group = "AI Gateway", datasource_type = "prometheus", expr = "max by (pod) (litellm_in_memory_spend_update_queue_size{container=\"litellm\"})", metric = "litellm_in_memory_spend_update_queue_depth", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_in_memory_spend_queue_warn", critical = "litellm_in_memory_spend_queue_crit" }
    litellm_in_memory_daily_spend_update_queue_size = { group = "AI Gateway", datasource_type = "prometheus", expr = "max by (pod) (litellm_in_memory_daily_spend_update_queue_size{container=\"litellm\"})", metric = "litellm_in_memory_daily_spend_queue_depth", type = "gt", dim_key = "", ok_when_nodata = true, warning = "litellm_in_memory_daily_spend_queue_warn", critical = "litellm_in_memory_daily_spend_queue_crit" }

    # ── Pod Saturation (ContainerInsights, CloudWatch) ───────────────────────
    litellm_pod_restarts           = { group = "AI Gateway", namespace = "ContainerInsights", metric = "pod_number_of_container_restarts", statistic = "Sum", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", warning = "litellm_pod_restarts_warn", critical = "litellm_pod_restarts_crit" }
    litellm_pod_memory_utilization = { group = "AI Gateway", namespace = "ContainerInsights", metric = "pod_memory_utilization", statistic = "Maximum", type = "gt", dim_key = "Namespace", dim_key2 = "ClusterName", warning = "litellm_pod_memory_warn", critical = "litellm_pod_memory_crit" }
  }
}