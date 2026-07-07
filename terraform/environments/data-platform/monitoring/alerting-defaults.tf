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

    # Same thresholds reused for the admin instance's equivalent rules
    litellm_deployment_state_admin_warn = 0
    litellm_deployment_state_admin_crit = 50
    litellm_provider_state_admin_warn   = 0
    litellm_provider_state_admin_crit   = 50

  }

  # Per-account effective thresholds: defaults merged with any account-specific
  # overrides (alert_account_configs[uid].threshold_overrides).
  alert_thresholds = {
    for env, cfg in local.grafana_monitored_accounts_by_uid :
    env => merge(local.alert_defaults, try(cfg.threshold_overrides, {}))
  }
}