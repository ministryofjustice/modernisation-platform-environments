moved {
  from = aws_cloudwatch_metric_alarm.dlq["eventbridge"]
  to   = module.cloudwatch_metric_alarms["eventbridge-dlq"].aws_cloudwatch_metric_alarm.this[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.dlq["sns"]
  to   = module.cloudwatch_metric_alarms["sns-dlq"].aws_cloudwatch_metric_alarm.this[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.dlq["processing"]
  to   = module.cloudwatch_metric_alarms["processing-dlq"].aws_cloudwatch_metric_alarm.this[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.lambda_errors
  to   = module.cloudwatch_metric_alarms["errors"].aws_cloudwatch_metric_alarm.this[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.record_failures
  to   = module.cloudwatch_metric_alarms["record-failures"].aws_cloudwatch_metric_alarm.this[0]
}
