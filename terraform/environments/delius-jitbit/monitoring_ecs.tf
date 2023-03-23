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
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${format("hmpps-%s-%s", local.environment, local.application_name)}",
            "ServiceName",
            "${local.application_name}"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "eu-west-2",
        "title": "CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "AWS/ECS",
            "MemoryUtilization",
            "ClusterName",
            "${format("hmpps-%s-%s", local.environment, local.application_name)}",
            "ServiceName",
            "${local.application_name}"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "eu-west-2",
        "title": "Memory Utilization"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 3,
      "width": 6,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "AWS/ECS",
            "DiskUtilization",
            "ClusterName",
            "${format("hmpps-%s-%s", local.environment, local.application_name)}",
            "ServiceName",
            "${local.application_name}"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "eu-west-2",
        "title": "Disk Utilization"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 3,
      "width": 6,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "AWS/ECS",
            "NetworkIn",
            "ClusterName",
            "${format("hmpps-%s-%s", local.environment, local.application_name)}",
            "ServiceName",
            "${local.application_name}"
          ]
        ],
        "period": 60,
        "stat": "Sum",
        "region": "eu-west-2",
        "title": "Network In"
      }
    }
  ]
}
EOF
}
