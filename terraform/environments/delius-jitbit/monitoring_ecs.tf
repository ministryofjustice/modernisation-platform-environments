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

# Alarm for high disk usage
resource "aws_cloudwatch_metric_alarm" "jitbit_disk_over_threshold" {
  alarm_name          = "jitbit-ecs-disk-threshold"
  alarm_description   = "Triggers alarm if ECS disk crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "DiskUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

# Alarm for high network traffic
resource "aws_cloudwatch_metric_alarm" "jitbit_ecs_network_over_threshold" {
  alarm_name          = "jitbit-ecs-network-threshold"
  alarm_description   = "Triggers alarm if ECS network crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "NetworkIn"
  statistic           = "Sum"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "1000000000"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

# aws cloudwatch dashboard for ECS Cluster

resource "aws_cloudwatch_dashboard" "jitbit_ecs_dashboard" {
  dashboard_name = "jitbit-ecs-dashboard"
  dashboard_body = <<EOF
    {
      "widgets" : [
        {
          "type" : "metric",
          "x" : 0,
          "y" : 0,
          "width" : 12,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "CPUUtilization", "ClusterName", "${local.application_name}", { "stat" : "Average", "period" : 60 }],
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "CPU Utilization"
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 0,
          "width" : 12,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "MemoryUtilization", "ClusterName", "${local.application_name}", { "stat" : "Average", "period" : 60 }],
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "Memory Utilization"
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 6,
          "width" : 12,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "DiskUtilization", "ClusterName", "${local.application_name}", { "stat" : "Average", "period" : 60 }],
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "Disk Utilization"
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 6,
          "width" : 12,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "NetworkIn", "ClusterName", "${local.application_name}", { "stat" : "Sum", "period" : 60 }],
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "Network In"
          }
        }
      ]
    }
  EOF
}
