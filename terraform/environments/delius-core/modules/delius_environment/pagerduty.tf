# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "delius_core_alarms" {
  name = var.sns_topic_name

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.env_name}-sns-topic"
    }
  )
}

# link the sns topic to the service
module "pagerduty_core_alerts" {

  depends_on = [
    aws_sns_topic.delius_core_alarms
  ]

  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.delius_core_alarms.name]
  pagerduty_integration_key = var.pagerduty_integration_key
}
