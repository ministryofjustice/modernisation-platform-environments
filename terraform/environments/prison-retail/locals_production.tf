# nomis-production environment settings
locals {

  baseline_presets_production = {
    options = {
      # TODO: configure prison-retail PagerDuty
      # sns_topics = {
      #   pagerduty_integrations = {
      #     pagerduty = "prison-retail"          
      #   }
      # }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {
  }
}
