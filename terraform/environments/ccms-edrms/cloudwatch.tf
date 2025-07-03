# CloudWatch Alarms for EDRMS Container Count

resource "aws_cloudwatch_metric_alarm" "container_count" {
  alarm_name                = "${local.application_name}-ecs-task-count"
  alarm_description         = "This alarm fires if the number of EDRMS ECS tasks is less than the threshold"
  comparison_operator       = "LessThanThreshold"
  metric_name               = "DesiredTaskCount"
  namespace                 = "ECS/ContainerInsights"
  statistic                 = "Average"
  period                    = 300
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = local.application_data.accounts[local.environment].app_count
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_slack.arn]
  insufficient_data_actions = []

  dimensions = {
    ServiceName = local.application_name
    ClusterName = "${local.application_name}-cluster"
  }
}
