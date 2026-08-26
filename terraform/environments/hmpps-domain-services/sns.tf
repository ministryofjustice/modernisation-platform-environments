resource "aws_sns_topic_subscription" "backup_failure_topic" {
  count     = local.environment == "preproduction" ? 1 : 0
  topic_arn = module.environment.backup_failure_topic.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/7a6a31bc364c440fd0b947bf41c9aa7f/enqueue"
}
