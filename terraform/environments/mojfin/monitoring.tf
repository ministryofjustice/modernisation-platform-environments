locals {
  # General
  region = "eu-west-2"
  # CloudWatch Alarms
  cpu_threshold = "90"
  cpu_alert_period = "60"
  cpu_evaluation_period = "30"
  memory_threshold = "1000000000"
  memory_alert_period = "60"
  memory_evaluation_period = "5"
  disk_free_space_threshold = "50000000000"
  disk_free_space_alert_period = "60"
  disk_free_space_evaluation_period = "1"
  read_latency_threshold = "0.5"
  read_latency_alert_period = "60"
  read_latency_evaluation_period = "5"

  #PagerDuty Integration
  sns_topic_name = "${local.application_name}-${local.environment}-alerting-topic"
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = "laa_mojfin_prod_alarms"
}

data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name         = "${local.application_name}-${local.environment}-CPU-utilization"
  alarm_description  = "The average CPU utilization is too high"
  namespace          = "AWS/RDS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = local.cpu_alert_period
  evaluation_periods = local.cpu_evaluation_period
  alarm_actions      = [aws_sns_topic.mojfin_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mojfin_alerting_topic.arn]
  threshold          = local.cpu_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_rds_instance.mojfin.db_name
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-CPU-utilization"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name         = "${local.application_name}-${local.environment}-free-memory"
  alarm_description  = "Average RDS memory usage exceeds the predefined threshold"
  namespace          = "AWS/RDS"
  metric_name        = "FreeableMemory"
  statistic          = "Average"
  period             = local.memory_alert_period
  evaluation_periods = local.memory_evaluation_period
  alarm_actions      = [aws_sns_topic.mojfin_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mojfin_alerting_topic.arn]
  threshold          = local.memory_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_rds_instance.mojfin.db_name
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-free-memory"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_diskspace" {
  alarm_name         = "${local.application_name}-${local.environment}-free-disk-space"
  alarm_description  = "EBS Volume - Disk Space is Low"
  namespace          = "AWS/RDS"
  metric_name        = "FreeStorageSpace"
  statistic          = "Average"
  period             = local.disk_free_space_alert_period
  evaluation_periods = local.disk_free_space_evaluation_period
  alarm_actions      = [aws_sns_topic.mojfin_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mojfin_alerting_topic.arn]
  threshold          = local.disk_free_space_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_rds_instance.mojfin.db_name
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-free-disk-space"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name         = "${local.application_name}-${local.environment}-read-latency"
  alarm_description  = "Read Latency Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "ReadLatency"
  statistic          = "Average"
  period             = local.read_latency_alert_period
  evaluation_periods = local.read_latency_evaluation_period
  alarm_actions      = [aws_sns_topic.mojfin_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mojfin_alerting_topic.arn]
  threshold          = local.read_latency_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_rds_instance.mojfin.db_name
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-read-latency"
    }
  )
}

resource "aws_cloudwatch_dashboard" "mlradash" {
  dashboard_name = "${local.application_name}-${local.environment}-dashboard"
  depends_on = [
    aws_cloudwatch_metric_alarm.rds_cpu,
    aws_cloudwatch_metric_alarm.rds_memory,
    aws_cloudwatch_metric_alarm.rds_diskspace,
    aws_cloudwatch_metric_alarm.rds_read_latency
  ]
  dashboard_body = <<EOF
  {
    "periodOverride": "inherit",
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "CPU Usage",
                "annotations": {
                    "alarms": [
                        "${aws_cloudwatch_metric_alarm.rds_cpu.arn}"
                    ]
                },
                "view": "timeSeries",
                "legend": {
                    "position": "hidden"
                },
                "period": 60,
                "region": "${local.region}",
                "stacked": true
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "Free Memory",
                "annotations": {
                    "alarms": [
                        "${aws_cloudwatch_metric_alarm.rds_memory.arn}"
                    ]
                },
                "view": "timeSeries",
                "legend": {
                    "position": "hidden"
                },
                "period": 60,
                "region": "${local.region}",
                "stacked": true
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "Free Disk Space",
                "annotations": {
                    "alarms": [
                        "${aws_cloudwatch_metric_alarm.rds_diskspace.arn}"
                    ]
                },
                "view": "timeSeries",
                "legend": {
                    "position": "hidden"
                },
                "period": 60,
                "region": "${local.region}",
                "stacked": true
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "ReadLatency",
                "annotations": {
                    "alarms": [
                        "${aws_cloudwatch_metric_alarm.rds_read_latency.arn}"
                    ]
                },
                "view": "timeSeries",
                "legend": {
                    "position": "bottom"
                },
                "period": 60,
                "region": "${local.region}",
                "stacked": true
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${aws_rds_instance.mojfin.db_name}" ]
                ],
                "region": "${local.region}"
            }
        },
        {
            "type": "alarm",
            "x": 0,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "Alarm Status",
                "alarms": [
                    "${aws_cloudwatch_metric_alarm.rds_cpu.arn}",
                    "${aws_cloudwatch_metric_alarm.rds_memory.arn}",
                    "${aws_cloudwatch_metric_alarm.rds_diskspace.arn}",
                    "${aws_cloudwatch_metric_alarm.rds_read_latency.arn}"
                ]
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/rds/instance/${local.application_name}/alert' | SOURCE '/aws/rds/instance/${local.application_name}/audit' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 20",
                "region": "${local.region}",
                "stacked": false,
                "view": "table"
            }
        }
    ]
  }
EOF
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "mojfin_alerting_topic" {
  name = local.sns_topic_name
  tags = merge(
    var.tags,
    {
      Name = local.sns_topic_name
    }
  )
}

resource "aws_sns_topic_subscription" "pagerduty_subscription" {
  topic_arn = aws_sns_topic.mojfin_alerting_topic.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${local.pagerduty_integration_keys[local.pagerduty_integration_key_name]}/enqueue"
}
