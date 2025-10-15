# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "delius_core_alarms" {
  name = "delius-core-${var.env_name}-alarms-topic"
  tags = var.tags
}

# link the sns topic to the service
module "pagerduty_core_alerts" {

  depends_on = [
    aws_sns_topic.delius_core_alarms
  ]

  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v3.0.0"
  sns_topics                = [aws_sns_topic.delius_core_alarms.name]
  pagerduty_integration_key = var.pagerduty_integration_key
}
