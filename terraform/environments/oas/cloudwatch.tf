locals {
  appnameenv               = "${local.application_name}-${local.environment}"
  sns_topic_name           = "${local.appnameenv}-alerting-topic"
  dashboard_name           = "${local.appnameenv}-Appication-Dashboard"
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  cloudwatch_metric_alarms = {
    ec2_cpu_utilisation_too_high = {
      alarm_name          = "${local.appnameenv}-EC2-CPU-High-Threshold-Alarm"
      alarm_description   = "Average CPU utilization is too high"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        InstanceId = "" # TODO
      }
      widget_name = "EC2 CPU Usage"
      # dashboard_widget_type = "metric"
      # coord_x = 0
      # coord_y = 0
      # dashboard_widget_height = 5
      # dashboard_widget_width = 8
      # dashboard_widget_view = "timeSeries"
      # dashboard_widget_refresh_period = 60

    },
    ec2_memory_over_threshold = {
      alarm_name          = "${local.appnameenv}--EC2-Memory-High-Threshold-Alarm"
      alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      metric_name         = "mem_used_percent"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId      = "" # TODO
        InstanceId   = "" # TODO
        InstanceType = "db.t3.small"
      }
      widget_name = "EC2 Memory Usage"
      # dashboard_widget_type = "metric"
      # coord_x = 0
      # coord_y = 1
      # dashboard_widget_height = 5
      # dashboard_widget_width = 8
      # dashboard_widget_view = "timeSeries"
      # dashboard_widget_refresh_period = 60
    },
    ebs_software_disk_space_used_over_threshold = {
      alarm_name          = "${local.appnameenv}-EBS-DiskSpace-Alarm"
      alarm_description   = "Software EBS volume - disk space is Low"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      metric_name         = "disk_used_percent"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId    = "" # TODO
        InstanceId = "" # TODO
        path       = "/oracle/software"
        fstype     = "ext4"
      }
      widget_name = "EBS Disk Usage"
      # dashboard_widget_type = "metric"
      # coord_x = 1
      # coord_y = 0
      # dashboard_widget_height = 5
      # dashboard_widget_width = 8
      # dashboard_widget_view = "timeSeries"
      # dashboard_widget_refresh_period = 60
    },
    ebs_root_disk_space_used_over_threshold = {
      alarm_name          = "${local.appnameenv}-EBS-Root-DiskSpace-Alarm"
      alarm_description   = "Root EBS volume - disk space is low"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      metric_name         = "disk_used_percent"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId    = "" # TODO
        InstanceId = "" # TODO
        path       = "/"
        fstype     = "xfs"
      }
      widget_name = "Root EBS Disk Usage"
      # dashboard_widget_type = "metric"
      # coord_x = 1
      # coord_y = 1
      # dashboard_widget_height = 5
      # dashboard_widget_width = 8
      # dashboard_widget_view = "timeSeries"
      # dashboard_widget_refresh_period = 60
    }
  }

  dashboard_widgets = [for widget in local.cloudwatch_metric_alarms : widget if widget.widget_name != null]
}

data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

module "cwalarm" {
  source = "./modules/cloudwatch"
  snsTopicName             = local.sns_topic_name
  cloudwatch_metric_alarms = local.cloudwatch_metric_alarms
  dashboard_widgets        = local.dashboard_widgets
  dashboard_name           = local.dashboard_name
}

module "pagerduty_core_alerts" {
  depends_on = [
    module.cwalarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [local.sns_topic_name]
  pagerduty_integration_key = local.pagerduty_integration_keys["core_alerts_cloudwatch"]
}
