# Terraform alarms for ECS Cluster

# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold" {
  alarm_name          = "jitbit-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
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

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold" {
  alarm_name          = "jitbit-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

# aws cloudwatch dashboard for ECS Cluster
resource "aws_cloudwatch_dashboard" "jitbit_ecs_dashboard" {
  dashboard_name = "jitbit-ecs-dashboard"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 8,
            "width": 11,
            "y": 0,
            "x": 11,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "CPUUtilization", "ClusterName", "hmpps-development-delius-jitbit", "ServiceName", "hmpps-development-delius-jitbit" ]
                ],
                "period": 60,
                "stat": "Average",
                "region": "eu-west-2",
                "title": "CPU Utilization"
            }
        },
        {
            "height": 8,
            "width": 11,
            "y": 8,
            "x": 11,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "MemoryUtilization", "ClusterName", "hmpps-development-delius-jitbit", "ServiceName", "hmpps-development-delius-jitbit" ]
                ],
                "period": 60,
                "stat": "Average",
                "region": "eu-west-2",
                "title": "Memory Utilization"
            }
        },
        {
            "type": "metric",
            "x": 5,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "JitbitMetrics", "ErrorCount", { "region": "eu-west-2", "color": "#d62728" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-west-2",
                "title": "Jitbit Application Error Count",
                "period": 300,
                "stat": "Average"
            }
        }
    ]
}
EOF
}
