locals {
  sns_topic_arn = module.baseline.sns_topics["dso_pagerduty"].id
}

resource "aws_cloudwatch_metric_alarm" "github_failed_actions" {
  alarm_name = "github-actions-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "FailedWorkflowRuns"
  namespace = "CustomMetrics"
  period = 21600
  statistic = "Average"
  threshold = 0
  alarm_description = "Alarm if the number of failed GitHub Actions runs is greater than 0"
  alarm_actions = [local.sns_topic_arn]
  ok_actions = [local.sns_topic_arn]
}
