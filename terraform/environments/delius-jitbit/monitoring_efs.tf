resource "aws_cloudwatch_metric_alarm" "lucene_efs_throughput_utilisation" {
  alarm_name          = "${local.application_name}-efs-throughput-utilisation"
  alarm_description   = "EFS throughput utilisation above 70%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]

  metric_query {
    id          = "m1"
    return_data = false

    metric {
      metric_name = "MeteredIOBytes"
      namespace   = "AWS/EFS"

      period = 60
      stat   = "Sum"

      dimensions = {
        FileSystemId = aws_efs_file_system.lucene.id
      }
    }
  }

  metric_query {
    id          = "m2"
    return_data = false

    metric {
      metric_name = "PermittedThroughput"
      namespace   = "AWS/EFS"

      period = 60
      stat   = "Average"

      dimensions = {
        FileSystemId = aws_efs_file_system.lucene.id
      }
    }
  }

  metric_query {
    id          = "e4"
    label       = "Throughput utilization (%)"
    expression  = "(m1 / PERIOD(m1)) * 100 / m2"
    return_data = true
  }

  tags = { Name = "${local.application_name}-efs-throughput-utilisation" }
}
