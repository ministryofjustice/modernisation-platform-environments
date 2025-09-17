resource "aws_cloudwatch_metric_alarm" "ccr_provider_load_lambda_error" {
  alarm_name          = "${aws_lambda_function.ccr_provider_load.function_name}-ErrorAlarm"
  alarm_description   = "Alarm when CCR Provider Load Lambda fails to invoke"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.ccr_provider_load.function_name
  }

  alarm_actions = [aws_sns_topic.hub2_alerts.arn]

  tags = merge(
    local.tags,
    {
      Name = "${aws_lambda_function.ccr_provider_load.function_name}-ErrorAlarm"
    }
  )
}