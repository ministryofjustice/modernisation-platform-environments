locals {
  pagerduty_integration_key_name = local.environment == "production" ? "hub2_prod_alarms" : "hub2_non_prod_alarms"
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "hub2_alerts" {
  name = "${local.application_name_short}-${local.environment}-slack-alerting-topic"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-slack-alerting-topic"
    }
  )
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.cwa
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.cwa.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.pagerduty_integration_key_name]
}