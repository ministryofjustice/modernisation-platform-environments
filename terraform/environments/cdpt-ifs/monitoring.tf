resource "aws_sns_topic" "lb_alarm_topic" {
  name = "lb_alarm_topic"
}

resource "aws_sns_topic_subscription" "slack_subscription" {
  topic_arn = aws_sns_topic.lb_alarm_topic.arn
  protocol  = "https"
  endpoint  = "https://hooks.slack.com/services/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"
}

resource "aws_cloudwatch_metric_alarm" "lb_5xx_errors" {
  alarm_name          = "lb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors 5xx errors on the load balancer"
  alarm_actions       = [aws_sns_topic.lb_alarm_topic.arn]

  dimensions = {
    LoadBalancer = "${local.application_name}-lb"
  }
}
