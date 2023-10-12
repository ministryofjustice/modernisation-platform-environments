# Alarm - "Redshift Health Status"
module "dpr_redshift_health_status_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-redshift-health-status-alarm"
  alarm_description   = "ATTENTION: DPR Redshift HealthStatus Monitor, Please investigate Redshift Errors !"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60

  namespace   = "AWS/Redshift"
  metric_name = "HealthStatus"
  statistic   = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Stop Monitor"
module "dpr_dms_stoptask_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-redshift-health-status-alarm"
  alarm_description   = "ATTENTION: DPR DMS Replication Stop Monitor, Please investigate DMS Replication Task Errors !"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1

  dimensions = {
    "Class"    = "None"
    "Resource" = "StopReplicationTask"
    "Service"  = "Database Migration Service"
    "Type"     = "API"
  }

  namespace    = "AWS/Usage"
  metric_name  = "CallCount"
  statistic    = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS CPU Utilization Monitor"
module "dpr_dms_cpu_utils_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-redshift-health-status-alarm"
  alarm_description   = "ATTENTION: DPR DMS Instance CPU Monitor, Please investigate High CPU Utilization for DMS Instance !"
  comparison_operator = "GreaterThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80

  namespace   = "AWS/DMS"
  metric_name = "HealthStatus"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}