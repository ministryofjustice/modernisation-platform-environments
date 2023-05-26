# Preset Pager Duty and Email SNS topics for use with baseline
# module
#
# var.options.sns_topics.pagerduty_integrations:
# - map key is sns topic name
# - map value is the key to use when looking up pager duty integration key
#   from the modernisation platform managed pagerduty_integration_keys
#
# var.options.sns_topics.email
# - map key is sns topic name
# - map value is the SSM parameter containining the email address

data "aws_ssm_parameter" "sns_topics_email" {
  for_each = var.options.sns_topics.emails

  name = each.value
}

locals {
  sns_topics_pagerduty_integrations = {
    for key, value in var.options.sns_topics.pagerduty_integrations : key => {
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

  sns_topics_emails = {
    for key, value in var.options.sns_topics.emails : key => {
      display_name      = "Email integration for ${value}"
      kms_master_key_id = "general"
      subscriptions = {
        "email" = {
          protocol = "email"
          endpoint = data.aws_ssm_parameter.sns_topics_email[key].value
        }
      }
    }
  }

  sns_topics = merge(
    local.sns_topics_pagerduty_integrations,
    local.sns_topics_emails
  )
}
