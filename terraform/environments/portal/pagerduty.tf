locals {
  sns_topic_name                 = "${local.application_name}-${local.environment}-alerting-topic"
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}


# For the Portal PagerDuty service
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

module "pagerduty_core_alerts" {
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [local.sns_topic_name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.pagerduty_integration_key_name]
}

resource "aws_sns_topic" "alerting_topic" {
  name = local.sns_topic_name
}
