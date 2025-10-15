# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "iaps_alerting" {
  name              = "${local.application_name}-alerting"
  kms_master_key_id = data.aws_kms_key.general_shared.arn
}

// ASG Alarms
resource "aws_cloudwatch_metric_alarm" "asg_cpu_utilization_over_threshold" {
  alarm_name                = "${local.application_name}-asg-cpu-utilization-over-threshold"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = [aws_sns_topic.iaps_alerting.arn]
  ok_actions                = [aws_sns_topic.iaps_alerting.arn]
  alarm_description         = "IAPs ASG CPU Utilization is greater than 80%"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group.name
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_failed_status_checks" {
  alarm_name                = "${local.application_name}-asg-failed-status-checks"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.iaps_alerting.arn]
  ok_actions                = [aws_sns_topic.iaps_alerting.arn]
  alarm_description         = "EC2 StatusCheckFailed for one or more instances in the IAPS ASG"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group.name
  }
}

resource "aws_cloudwatch_metric_alarm" "in_service_instances_below_threshold" {
  alarm_name                = "${local.application_name}-asg-in-service-instances"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "GroupInServiceInstances"
  namespace                 = "AWS/AutoScaling"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.iaps_alerting.arn]
  ok_actions                = [aws_sns_topic.iaps_alerting.arn]
  alarm_description         = "There is less than 1 instance InService for ec2 IAPS ASG"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group.name
  }
}

// Nginx Alarms
resource "aws_cloudwatch_log_metric_filter" "nginx_connect_error" {
  name           = "NginxConnectError"
  pattern        = "\"[error]\" \"connect() failed\""
  log_group_name = aws_cloudwatch_log_group.cloudwatch_agent_log_groups["error.log"].name

  metric_transformation {
    name      = "NginxConnectError"
    namespace = "IAPS"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "nginx_connect_error" {
  alarm_name          = "${local.application_name}-high-nginx-connect-error-count"
  alarm_description   = "Triggers alarm if there are consistent upstream connection errors"
  namespace           = "IAPS"
  metric_name         = "NginxConnectError"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "1"
  alarm_actions       = [aws_sns_topic.iaps_alerting.arn]
  ok_actions          = [aws_sns_topic.iaps_alerting.arn]
  threshold           = "3"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

// Delius Interface Alarms
resource "aws_cloudwatch_log_metric_filter" "interface_low_level_error" {
  name           = "IapsNDeliusInterfaceLowLevelError"
  pattern        = "\"LOW LEVEL ERROR - WAIT for 50 seconds\""
  log_group_name = aws_cloudwatch_log_group.cloudwatch_agent_log_groups["ndinterface/xmltransfer.log"].name

  metric_transformation {
    name      = "NDeliusInterfaceLowLevelError"
    namespace = "IAPS"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "interface_low_level_error" {
  alarm_name          = "${local.application_name}-high-ndelius-interface-low-level-errors"
  alarm_description   = "Triggers alarm if there are consistent NDelius Interface low level errors"
  namespace           = "IAPS"
  metric_name         = "NDeliusInterfaceLowLevelError"
  statistic           = "Sum"
  period              = "180"
  evaluation_periods  = "1"
  alarm_actions       = [aws_sns_topic.iaps_alerting.arn]
  ok_actions          = [aws_sns_topic.iaps_alerting.arn]
  threshold           = "3"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

// RDS Alarms
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_over_threshold" {
  alarm_name          = "${local.application_name}-rds-cpu-utilization-over-threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "180"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors CPU utilization for the RDS instance"
  alarm_actions       = [aws_sns_topic.iaps_alerting.arn]
  ok_actions          = [aws_sns_topic.iaps_alerting.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.iaps.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  alarm_name          = "${local.application_name}-rds-free-storage-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "104857600" # 100 GB
  alarm_description   = "This metric monitors free storage space for the RDS instance"
  alarm_actions       = [aws_sns_topic.iaps_alerting.arn]
  ok_actions          = [aws_sns_topic.iaps_alerting.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.iaps.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_metrics_missing" {
  alarm_name          = "${local.application_name}-rds-missing-metrics"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  treat_missing_data  = "breaching"
  threshold           = "0" # CPU will never go to 0 in normal operation, so only missing metrics will trigger this alarm
  alarm_description   = "This metric monitors missing RDS metrics to prompt for an investigation for why metrics are missing"
  alarm_actions       = [aws_sns_topic.iaps_alerting.arn]
  ok_actions          = [aws_sns_topic.iaps_alerting.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.iaps.identifier
  }
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  integration_key_lookup     = local.is-production ? "iaps_prod_alarms" : "iaps_nonprod_alarms"
}

# link the sns topic to the service
# Non-Prod alerts channel: #hmpps-iaps-alerts-non-prod
# Prod alerts channel:     #hmpps-iaps-alerts-prod
#checkov:skip=CKV_AWS_108: "Ensure IAM policies does not allow data exfiltration"
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.iaps_alerting
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v3.0.0"
  sns_topics                = [aws_sns_topic.iaps_alerting.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.integration_key_lookup]
}
