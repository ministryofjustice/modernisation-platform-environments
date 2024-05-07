locals {
  sns_topic_arn = module.baseline.sns_topics["dso_pagerduty"].id
}

resource "aws_cloudwatch_metric_alarm" "github_failed_actions" {
  alarm_name          = "github-actions-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "FailedWorkflowRuns"
  namespace           = "CustomMetrics"
  evaluation_periods  = 72
  threshold           = 1
  datapoints_to_alarm = 1
  statistic           = "Maximum"
  period              = 300
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm if the number of failed GitHub Actions runs is greater than 0"

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]
}
