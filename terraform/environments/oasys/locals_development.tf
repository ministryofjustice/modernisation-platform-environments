# environment specific settings
locals {

  # cloudwatch monitoring config
  development_cloudwatch_monitoring_options = {}

  development_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_nonprod_alarms"
        dba_pagerduty               = "hmpps_shef_dba_non_prod"
        dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      }
    }
  }

  development_config = {}
}
