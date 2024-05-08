locals {
  sns_topic_arn = module.baseline.sns_topics["dso_pagerduty"].id
}

resource "aws_cloudwatch_metric_alarm" "github_failed_actions" {
  alarm_name          = "github-actions-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "breaching"
  alarm_description   = "Alarm if the number of failed GitHub Actions runs is greater than 0"
  metric_query {
    id         = "m1"
    period = 600
    expression = "SEARCH('{CustomMetrics,Repository} MetricName=\"FailedWorkflowRuns\"', 'Maximum', 600)"
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]
}
