locals {
  alert_defaults = {
    # -------------------------------------------------------------------------
    # AI Gateway
    # -------------------------------------------------------------------------
    # Thresholds are failure-rate percentages (0–100) from the health-check queries above.
    # litellm_deployment_state_warning: per-model query, warning only — fires per-model on any failure (>0%).
    # litellm_deployment_state_critical: aggregate query, critical only — fires when a majority of all models are failing (>50%).
    litellm_deployment_state_warn = 0  # % failure for an individual model — fires warning on state > 0
    litellm_deployment_state_crit = 50 # % of ALL models currently failing — fires critical on state > 50 (majority outage)

    litellm_provider_state_warn = 0  # % of models within a provider failing health checks — fires on state > 0
    litellm_provider_state_crit = 50 # % of models within a provider failing health checks — fires on state > 50

    litellm_model_no_healthy_deployments_crit = 0 # any positive delta = model has zero healthy deployments (all cooled down)

    # ── Proxy Errors & Traffic ──────────────────────────────────────────────
    litellm_proxy_failed_requests_warn          = 1    # % of all proxy requests failing
    litellm_proxy_failed_requests_crit          = 5    # % of all proxy requests failing
    litellm_proxy_failed_requests_by_model_crit = 10   # % — higher than global threshold; per-model traffic is noisier
    litellm_proxy_traffic_baseline_warn         = -50  # fire when traffic is 50% below 1h-ago rate
    litellm_proxy_traffic_baseline_crit         = -80  # fire when traffic is 80% below 1h-ago rate
    litellm_proxy_zero_traffic_crit             = 0.01 # req/s floor treated as effectively zero — pairs with ok_when_nodata=false
    litellm_proxy_429_pct_warn                  = 10   # % of requests self-throttled — capacity signal, warning-only
    litellm_callback_logging_failures_warn      = 5    # raw count of callback logging failures per 5m
    litellm_callback_logging_failures_crit      = 20   # raw count of callback logging failures per 5m

    # ── Latency (seconds) ───────────────────────────────────────────────────
    litellm_proxy_latency_p99_warn            = 10   # total request latency p99, seconds
    litellm_proxy_latency_p99_crit            = 15   # total request latency p99, seconds
    litellm_llm_api_latency_p99_warn          = 10   # LLM API latency p99, seconds
    litellm_llm_api_latency_p99_crit          = 30   # LLM API latency p99, seconds
    litellm_ttft_p99_warn                     = 3    # time-to-first-token p99, seconds
    litellm_ttft_p99_crit                     = 8    # time-to-first-token p99, seconds
    litellm_in_flight_requests_warn           = 100  # concurrent in-flight requests across all pods
    litellm_in_flight_requests_crit           = 250  # concurrent in-flight requests across all pods
    litellm_overhead_latency_p99_warn         = 1    # LiteLLM-added processing overhead p99, seconds
    litellm_overhead_latency_p99_crit         = 2    # LiteLLM-added processing overhead p99, seconds
    litellm_deployment_latency_per_token_warn = 0.75 # seconds per output token, p99
    litellm_deployment_latency_per_token_crit = 1.5  # seconds per output token, p99

    # ── Deployment Health ────────────────────────────────────────────────────
    litellm_cooldown_events_warn  = 1 # raw count of cooldown events per 5m, per model
    litellm_cooldown_events_crit  = 5 # raw count of cooldown events per 5m, per model
    litellm_failed_fallbacks_warn = 1 # raw count of failed fallback attempts per 5m
    litellm_failed_fallbacks_crit = 5 # raw count of failed fallback attempts per 5m

    # ── Rate-Limit ──────────────────────────────────────────────────
    litellm_remaining_requests_warn         = 50   # remaining requests before provider rate limit, per model/provider
    litellm_remaining_requests_crit         = 10   # remaining requests before provider rate limit, per model/provider
    litellm_remaining_tokens_warn           = 5000 # remaining tokens before provider rate limit, per model/provider
    litellm_remaining_tokens_crit           = 1000 # remaining tokens before provider rate limit, per model/provider
    litellm_api_key_remaining_requests_warn = 20   # remaining requests before per-key model rate limit
    litellm_api_key_remaining_requests_crit = 5    # remaining requests before per-key model rate limit
    litellm_api_key_remaining_tokens_warn   = 2000 # remaining tokens before per-key model rate limit
    litellm_api_key_remaining_tokens_crit   = 500  # remaining tokens before per-key model rate limit

    # ── Budget (GBP remaining) ──────────────────────────────────────────────
    litellm_team_budget_remaining_warn    = 50 # £ remaining before warning, per team
    litellm_team_budget_remaining_crit    = 10 # £ remaining before critical, per team
    litellm_api_key_budget_remaining_warn = 20 # £ remaining before warning, per key
    litellm_api_key_budget_remaining_crit = 5  # £ remaining before critical, per key

    # ── Redis ────────────────────────────────────────────────────────────────
    litellm_redis_failure_rate_warn = 5   # raw count of Redis call failures per 5m
    litellm_redis_failure_rate_crit = 20  # raw count of Redis call failures per 5m
    litellm_redis_latency_p99_warn  = 0.1 # Redis latency p99, seconds
    litellm_redis_latency_p99_crit  = 0.5 # Redis latency p99, seconds

    # ── Internal Self Latency ────────────────────────────────────────────────
    litellm_self_latency_p99_warn = 5  # internal SDK latency p99, seconds
    litellm_self_latency_p99_crit = 10 # internal SDK latency p99, seconds

    # ── Spend Queue Backpressure ────────────────────────────────────────────
    litellm_redis_spend_queue_warn           = 100  # queued spend updates in Redis
    litellm_redis_spend_queue_crit           = 500  # queued spend updates in Redis
    litellm_redis_daily_spend_queue_warn     = 100  # queued daily spend updates in Redis
    litellm_redis_daily_spend_queue_crit     = 500  # queued daily spend updates in Redis
    litellm_in_memory_spend_queue_warn       = 500  # queued spend updates in-memory, per pod
    litellm_in_memory_spend_queue_crit       = 2000 # queued spend updates in-memory, per pod
    litellm_in_memory_daily_spend_queue_warn = 500  # queued daily spend updates in-memory, per pod
    litellm_in_memory_daily_spend_queue_crit = 2000 # queued daily spend updates in-memory, per pod

    # ── Pod Saturation (ContainerInsights) ───────────────────────────────────
    litellm_pod_restarts_warn = 1
    litellm_pod_restarts_crit = 3
    litellm_pod_memory_warn   = 80 # % of container memory limit
    litellm_pod_memory_crit   = 95 # % of container memory limit
  }
  # Per-account effective thresholds: defaults merged with any account-specific
  # overrides (alert_account_configs[uid].threshold_overrides).
  alert_thresholds = {
    for env, cfg in local.grafana_monitored_accounts_by_uid :
    env => merge(local.alert_defaults, try(cfg.threshold_overrides, {}))
  }
}