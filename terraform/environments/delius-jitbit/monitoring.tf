# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "jitbit_alerting" {
  name = "jitbit_alerting"
}

resource "aws_sns_topic_subscription" "jitbit_pagerduty_subscription" {
  topic_arn = aws_sns_topic.jitbit_alerting.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${local.pagerduty_integration_keys["jitbit_nonprod_alarms"]}/enqueue"
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
    aws_sns_topic.jitbit_alerting
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.jitbit_alerting.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["jitbit_nonprod_alarms"]
}
