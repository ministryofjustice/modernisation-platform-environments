locals {
  alert_defaults = {
    # -------------------------------------------------------------------------
    # AI Gateway
    # -------------------------------------------------------------------------
    # Thresholds are failure-rate percentages (0–100) from the health-check queries above.
    litellm_deployment_state_warn = 0 # % of failed health-check requests for a given model/deployment — fires on state > 0  → catches any failure at all (even a single blip)
    litellm_deployment_state_crit = 1 # % of failed health-check requests for a given model/deployment — fires on state > 1  → catches sustained/repeated failures, not just a one-off blip

    litellm_provider_state_warn = 90 # % of models within a provider failing health checks — fires on state > 90 → catches early signs most models for that provider are down
    litellm_provider_state_crit = 99 # % of models within a provider failing health checks — fires on state > 99 → catches near-total/total provider outage

    # Same thresholds reused for the admin instance's equivalent rules
    litellm_deployment_state_admin_warn = 0
    litellm_deployment_state_admin_crit = 1
    litellm_provider_state_admin_warn   = 90
    litellm_provider_state_admin_crit   = 99

  }

  # Per-account effective thresholds: defaults merged with any account-specific
  # overrides (alert_account_configs[uid].threshold_overrides).
  alert_thresholds = {
    for env, cfg in local.grafana_monitored_accounts_by_uid :
    env => merge(local.alert_defaults, try(cfg.threshold_overrides, {}))
  }
}