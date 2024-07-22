locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty = "nomis_data_hub_nonprod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {
  }
}
