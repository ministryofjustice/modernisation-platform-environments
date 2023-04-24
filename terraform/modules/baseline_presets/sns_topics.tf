# Use var.options.sns_topics_pagerduty_integrations to control, where
# the map key is the sns_topic name and value is the index to use in
# the modernisation platform managed pagerduty_integration_keys
# secret,  e.g.
# var.options.sns_topics_pagerduty_integrations = {
#   prod_alarms    = nomis_alarms
#   nonprod_alarms = nomis_nonprod_alarms
# }

locals {
  sns_topic_pagerduty_integrations = {
    for key, value in var.options.sns_topics_pagerduty_integrations : key => {
      display_name      = "Pager duty integration for ${value}"
      kms_master_key_id = "general"
      subscriptions = {
        "${key}" = {
          protocol = "https"
          endpoint = "https://events.pagerduty.com/integration/${var.environment.pagerduty_integration_keys[value]}/enqueue"
        }
      }
    }
  }
}
