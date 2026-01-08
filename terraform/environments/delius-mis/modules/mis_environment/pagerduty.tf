resource "aws_sns_topic" "delius_mis_alarms" {
  name = "${var.app_name}-${var.env_name}-sns-topic"

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-${var.env_name}-sns-topic"
    }
  )
}

module "pagerduty_core_alerts" {

  depends_on = [
    aws_sns_topic.delius_mis_alarms
  ]

  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v3.0.0"
  sns_topics                = [aws_sns_topic.delius_mis_alarms.name]
  pagerduty_integration_key = var.pagerduty_integration_key
}
