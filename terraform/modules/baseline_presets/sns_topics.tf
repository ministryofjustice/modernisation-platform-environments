# Preset Pager Duty SNS topics for use with baseline module
#
# var.options.sns_topics.pagerduty_integrations:
# - map key is sns topic name
# - map value is the key to use when looking up pager duty integration key
#   from the modernisation platform managed pagerduty_integration_keys

locals {

  pagerduty_integrations = merge(
    var.options.enable_ssm_command_monitoring ? { dso-pipelines-pagerduty = "dso-pipelines" } : {},
    var.options.sns_topics.pagerduty_integrations
  )

  sns_topics_pagerduty_integrations = {
    for key, value in local.pagerduty_integrations : key => {
      display_name      = "Pager duty integration for ${value}"
      kms_master_key_id = "general"
      subscriptions = {
        (key) = {
          protocol = "https"
          endpoint = "https://events.pagerduty.com/integration/${var.environment.pagerduty_integration_keys[value]}/enqueue"
        }
      }
    }
  }

  sns_topics = merge(
    local.sns_topics_pagerduty_integrations,
  )
}
