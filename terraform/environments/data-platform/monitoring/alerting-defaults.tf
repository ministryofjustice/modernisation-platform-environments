locals {
  alert_defaults = {
    # -------------------------------------------------------------------------
    # AI Gateway
    # -------------------------------------------------------------------------
    litellm_deployment_state_warn = 0   # fires on state > 0  → catches 1 (partial) or 2 (complete)
    litellm_deployment_state_crit = 1   # fires on state > 1  → catches 2 (complete) only

    litellm_provider_state_warn = 90 
    litellm_provider_state_crit = 99

    litellm_bedrock_exception_rate_warn = 0
litellm_bedrock_exception_rate_crit = 1

  }

  # Per-account effective thresholds: defaults merged with any account-specific
  # overrides (alert_account_configs[uid].threshold_overrides).
alert_thresholds = {
    for env, cfg in local.grafana_monitored_accounts_by_uid :
    env => merge(local.alert_defaults, try(cfg.threshold_overrides, {}))
  }
}