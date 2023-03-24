resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name          = "jitbit-rds-cpu-threshold"
  alarm_description   = "Triggers alarm if RDS CPU crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ram_over_threshold" {
  alarm_name          = "jitbit-rds-ram-threshold"
  alarm_description   = "Triggers alarm if RDS RAM crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "2500000000"
  treat_missing_data  = "missing"
  comparison_operator = "LessThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "read_latency_over_threshold" {
  alarm_name          = "jitbit-rds-read-latency-threshold"
  alarm_description   = "Triggers alarm if RDS read latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "write_latency_over_threshold" {
  alarm_name          = "jitbit-rds-write-latency-threshold"
  alarm_description   = "Triggers alarm if RDS write latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "db_connections_over_threshold" {
  alarm_name          = "jitbit-rds-db-connections-threshold"
  alarm_description   = "Triggers alarm if RDS database connections crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "100"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_dashboard" "jitbit_rds" {
  dashboard_name = "jitbit_rds"
  depends_on = [
    aws_cloudwatch_metric_alarm.cpu_over_threshold,
    aws_cloudwatch_metric_alarm.ram_over_threshold,
    aws_cloudwatch_metric_alarm.read_latency_over_threshold,
  ]
  dashboard_body = <<EOF
  {
    "widgets": [
        {
            "type": "explorer",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 15,
            "properties": {
                "metrics": [
                    {
                        "metricName": "FreeableMemory",
                        "resourceType": "AWS::RDS::DBInstance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "ReadLatency",
                        "resourceType": "AWS::RDS::DBInstance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "CPUUtilization",
                        "resourceType": "AWS::RDS::DBInstance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "WriteLatency",
                        "resourceType": "AWS::RDS::DBInstance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "DatabaseConnections",
                        "resourceType": "AWS::RDS::DBInstance",
                        "stat": "Average"
                    }
                ],
                "labels": [
                    {
                        "key": "Name",
                        "value": "delius-jitbit-${local.environment}-database"
                    }
                ],
                "widgetOptions": {
                    "legend": {
                        "position": "bottom"
                    },
                    "view": "timeSeries",
                    "stacked": false,
                    "rowsPerPage": 50,
                    "widgetsPerRow": 2
                },
                "period": 300,
                "splitBy": "",
                "region": "eu-west-2"
            }
        }
      ]
    }
  EOF
}
