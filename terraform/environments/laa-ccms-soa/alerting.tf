#--Alerting Chatbot
module "chatbot_nonprod" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  count            = local.is-production ? 0 : 1
  slack_channel_id = local.application_data.accounts[local.environment].alerting_slack_channel_id
  sns_topic_arns   = [aws_sns_topic.alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_data.accounts[local.environment].app_name
}

module "chatbot_prod" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  count            = local.is-production ? 1 : 0
  slack_channel_id = local.application_data.accounts[local.environment].alerting_slack_channel_id
  sns_topic_arns   = [aws_sns_topic.alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_data.accounts[local.environment].app_name
}

module "guardduty_chatbot_nonprod" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  count            = local.is-production ? 0 : 1
  slack_channel_id = data.aws_secretsmanager_secret_version.slack_channel_id.secret_string
  sns_topic_arns   = [aws_sns_topic.guardduty_alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_data.accounts[local.environment].app_name
}

module "guardduty_chatbot_prod" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  count            = local.is-production ? 1 : 0
  slack_channel_id = data.aws_secretsmanager_secret_version.slack_channel_id.secret_string
  sns_topic_arns   = [aws_sns_topic.guardduty_alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_data.accounts[local.environment].app_name
}

#--Altering SNS
resource "aws_sns_topic" "alerts" {
  name            = "${local.application_data.accounts[local.environment].app_name}-alerts"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerting_sns.json
}

resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_sns_topic" "guardduty_alerts" {
  name            = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
}

resource "aws_sns_topic_policy" "guarduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
}

resource "aws_sns_topic_subscription" "guardduty_alerts" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

#--Alerts RDS
resource "aws_db_event_subscription" "rds_events" {
  name        = "${local.application_data.accounts[local.environment].app_name}-rds-event-sub"
  sns_topic   = aws_sns_topic.alerts.arn
  source_type = "db-instance"
  source_ids  = [aws_db_instance.soa_db.identifier]
  event_categories = [
    "availability",
    "configuration change",
    "deletion",
    "failover",
    "failure",
    "low storage",
    "maintenance",
    "notification",
    "recovery",
    "restoration",
  ]
}

resource "aws_cloudwatch_metric_alarm" "RDS_CPU_over_threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-CPU-high-threshold-alarm"
  alarm_description   = "${local.aws_account_id} | RDS CPU is above 75% for over 15 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "300"
  evaluation_periods  = "3"
  threshold           = "75"
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "RDS_Disk_Queue_Depth_Over_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-DiskQueue-high-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | RDS disk queue is above 4 for over 15 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "300"
  evaluation_periods  = "3"
  threshold           = "4"
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "RDS_Free_Storage_Space_Over_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-FreeStorageSpace-low-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | RDS Free storage space is below 50 for over 15 minutes"
  comparison_operator = "LessThanThreshold"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "300"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  threshold           = local.application_data.accounts[local.environment].logging_cloudwatch_rds_free_storage_threshold_gb
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "RDS_Burst_Balance_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-BurstBalance-low-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | RDS Burst balance is below 1 for over 15 minutes"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "BurstBalance"
  statistic           = "Sum"
  namespace           = "AWS/RDS"
  period              = "300"
  evaluation_periods  = "3"
  threshold           = "1"
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "RDS_Write_IOPS_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-WriteIOPS-high-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | RDS Write IOPS is above ${local.application_data.accounts[local.environment].logging_cloudwatch_rds_write_iops_threshold} for over 15 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "WriteIOPS"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "300"
  datapoints_to_alarm = "3"
  evaluation_periods  = "3"
  threshold           = local.application_data.accounts[local.environment].logging_cloudwatch_rds_write_iops_threshold
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "RDS_Read_IOPS_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-RDS-ReadIOPS-high-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | RDS Read IOPS is above ${local.application_data.accounts[local.environment].logging_cloudwatch_rds_read_iops_threshold} for over 15 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "ReadIOPS"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "300"
  datapoints_to_alarm = "3"
  evaluation_periods  = "3"
  threshold           = local.application_data.accounts[local.environment].logging_cloudwatch_rds_read_iops_threshold
  treat_missing_data  = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.soa_db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts ECS
resource "aws_cloudwatch_metric_alarm" "admin_service_cpu_high" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-admin-cpu-utilization-high"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Admin ECS average CPU usage is above 85% for over 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.admin.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "Admin_Ecs_Memory_Over_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-Admin-ECS-Memory-high-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Admin ECS average memory usage is above 95% for over 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  namespace           = "AWS/ECS"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "95"
  treat_missing_data  = "breaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.admin.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "managed_service_cpu_high" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-cpu-utilization-high"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Managed ECS average CPU usage is above 85% for over 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.managed.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "Managed_Ecs_Memory_Over_Threshold" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-Managed-ECS-Memory-high-threshold-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Managed Server ECS average memory usage is above 75% for over 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  namespace           = "AWS/ECS"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "95"
  treat_missing_data  = "breaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.managed.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts EC2 (Admin)
resource "aws_cloudwatch_metric_alarm" "EC2_CPU_over_Threshold_admin" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-EC2-CPU-high-threshold-alarm-admin"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA EC2 CPU utilisation is above 85% for over 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "85"
  treat_missing_data  = "breaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group-admin.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure_admin" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-status-check-failure-alarm-admin"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | A SOA EC2 Admin instance has failed a status check for over 2 minutes. This likely means that the instance has crashed and may need manual intervention."
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "2"
  threshold           = "1"
  treat_missing_data  = "breaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group-admin.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts EC2 (Managed)
resource "aws_cloudwatch_metric_alarm" "EC2_CPU_over_Threshold_managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-EC2-CPU-high-threshold-alarm-managed"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA EC2 CPU utilisation is above 85% for over 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "85"
  treat_missing_data  = "breaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group-managed.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure_managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-status-check-failure-alarm-managed"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | A SOA EC2 Managed instance has failed a status check for over 2 minutes. This likely means that the instance has crashed and may need manual intervention."
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "breaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group-managed.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts NLB (Admin)
resource "aws_cloudwatch_metric_alarm" "Admin_UnHealthy_Hosts" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-admin-unhealthy-hosts-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There is an unhealthy host in the target group ${aws_lb_target_group.admin.name} for over 15 minutes, this likely means that an admin host has failed to boot correctly"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  evaluation_periods  = "15"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.admin.arn_suffix
    TargetGroup  = aws_lb_target_group.admin.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts NLB (Managed)
resource "aws_cloudwatch_metric_alarm" "Managed_UnHealthy_Hosts" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-unhealthy-hosts-alarm"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There is an unhealthy host in the target group ${aws_lb_target_group.managed.name} for over 15 minutes, this likely means that a managed host has failed to boot correctly"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  evaluation_periods  = "15"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.managed.arn_suffix
    TargetGroup  = aws_lb_target_group.managed.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts (EFS)
resource "aws_cloudwatch_metric_alarm" "soa_low_efs_burst_balance" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-efs-burst-balance-low"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | EFS burst balance is low, consider raising the size of the volume https://docs.aws.amazon.com/efs/latest/ug/performance.html"
  comparison_operator = "LessThanThreshold"
  metric_name         = "BurstCreditBalance"
  statistic           = "Average"
  namespace           = "AWS/EFS"
  period              = "300"
  evaluation_periods  = "1"
  threshold           = "10737418240"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    FileSystemId = aws_efs_file_system.storage.id
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

#--Alerts (Application Layer)
resource "aws_cloudwatch_metric_alarm" "SOA_Benefit_Checker_Managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-benefit-checker"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Reporting unable to connect to Benefit Checker for last 30 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_benefit_checker_managed.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "1800"
  evaluation_periods  = "1"
  threshold           = "100"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "SOA_Benefit_Checker_Admin" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-admin-benefit-checker"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | SOA Reporting unable to connect to Benefit Checker for last 30 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_benefit_checker_admin.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "1800"
  evaluation_periods  = "1"
  threshold           = "100"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "SOA_Custom_Checks_Error_Managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-custom-checks-errors"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There have been multiple custom check script errors on the SOA managed servers in the last 5 minutes, this likely means please that a composite endpoint is unreachable."
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_custom_checks_error_managed.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "300"
  evaluation_periods  = "1"
  threshold           = "5"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

#--The below alerts have been disabled as we do not understand their benefit and if the errors being thrown are actually errors
#--or just part of the regular operation of the CCMS application

/* resource "aws_cloudwatch_metric_alarm" "SOA_Stuck_Thread_Managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-stuck-thread"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There is a SOA stuck thread active for last 30 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_stuck_thread_managed.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "3600"
  evaluation_periods  = "1"
  threshold           = "50"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "SOA_Stuck_Thread_Admin" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-admin-stuck-thread"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There is a SOA stuck thread active for last 30 minutes"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_stuck_thread_admin.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "3600"
  evaluation_periods  = "1"
  threshold           = "50"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "SOA_Benefit_Checker_Rollback_Error_Managed" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-managed-benefit-checker-rollback-errors"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There have been multiple instances of benefit checker transactions being rolled back on the SOA managed servers in the last 5 minutes, please investigate, runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_benefit_checker_rollback_error_managed.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "300"
  evaluation_periods  = "1"
  threshold           = "120"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "SOA_Benefit_Checker_Rollback_Error_Admin" {
  alarm_name          = "${local.application_data.accounts[local.environment].app_name}-admin-benefit-checker-rollback-errors"
  alarm_description   = "${local.environment} | ${local.aws_account_id} | There have been multiple instances of benefit checker transactions being rolled back on the SOA admin servers in the last 5 minutes, please investigate, runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.soa_benefit_checker_rollback_error_admin.id
  statistic           = "Sum"
  namespace           = "CCMS-SOA-APP"
  period              = "300"
  evaluation_periods  = "1"
  threshold           = "50"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
} */

resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${local.application_name}-guardduty-findings"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule = aws_cloudwatch_event_rule.guardduty.name
  arn  = aws_sns_topic.guardduty_alerts.arn
}

