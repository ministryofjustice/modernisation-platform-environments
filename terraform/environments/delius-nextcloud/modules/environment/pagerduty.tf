# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "delius_nextcloud_alarms" {
  name = "delius-nextcloud-${var.env_name}-alarms-topic"

  tags = var.tags
}

# link the sns topic to the service
module "pagerduty_nextcloud_alerts" {

  depends_on = [
    aws_sns_topic.delius_nextcloud_alarms
  ]

  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.delius_nextcloud_alarms.name]
  pagerduty_integration_key = var.pagerduty_integration_key
}
