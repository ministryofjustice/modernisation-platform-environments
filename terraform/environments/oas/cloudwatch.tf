locals {
  appnameenv                     = "${local.application_name}-${local.environment}"
  sns_topic_name                 = "${local.appnameenv}-alerting-topic"
  dashboard_name                 = "${local.appnameenv}-Appication-Dashboard"
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
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
        InstanceId = aws_instance.oas_app_instance.id
      }

    },
    ec2_memory_over_threshold = {
      alarm_name          = "${local.appnameenv}--EC2-Memory-High-Threshold-Alarm"
      alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      metric_name         = "mem_used_percent"
      namespace           = "CWAgent" # TODO CW Agent on in Instance yet so need confirming metrics are sending across to CW once AMI implemented
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId      = local.application_data.accounts[local.environment].ec2amiid
        InstanceId   = aws_instance.oas_app_instance.id
        InstanceType = "db.t3.small"
      }

    },
    ebs_software_disk_space_used_over_threshold = {
      alarm_name          = "${local.appnameenv}-EBS-DiskSpace-Alarm"
      alarm_description   = "Software EBS volume - disk space is Low"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      metric_name         = "disk_used_percent"
      namespace           = "CWAgent" # TODO CW Agent on in Instance yet so need confirming metrics are sending across to CW once AMI implemented
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId    = local.application_data.accounts[local.environment].ec2amiid
        InstanceId = aws_instance.oas_app_instance.id
        path       = "/oracle/software"
        fstype     = "ext4"
      }

    },
    ebs_root_disk_space_used_over_threshold = {
      alarm_name          = "${local.appnameenv}-EBS-Root-DiskSpace-Alarm"
      alarm_description   = "Root EBS volume - disk space is low"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      metric_name         = "disk_used_percent"
      namespace           = "CWAgent" # TODO CW Agent on in Instance yet so need confirming metrics are sending across to CW once AMI implemented
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      treat_missing_data  = "breaching"
      dimensions = {
        ImageId    = local.application_data.accounts[local.environment].ec2amiid
        InstanceId = aws_instance.oas_app_instance.id
        path       = "/"
        fstype     = "xfs"
      }

    }
  }

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
  source                          = "./modules/cloudwatch"
  snsTopicName                    = local.sns_topic_name
  cloudwatch_metric_alarms        = local.cloudwatch_metric_alarms
  dashboard_name                  = local.dashboard_name
  dashboard_widget_refresh_period = local.application_data.accounts[local.environment].dashboard_widget_period
}

module "pagerduty_core_alerts" {
  depends_on = [
    module.cwalarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [local.sns_topic_name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.pagerduty_integration_key_name]
}
