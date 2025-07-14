## Monitoring Amazon Redshift, https://docs.aws.amazon.com/redshift/latest/mgmt/metrics-listing.html
# Alarm - "Redshift Health Status"
# Indicates the health of the cluster. Every minute the cluster connects to its database and performs a simple query. 
# If it is able to perform this operation successfully, the cluster is considered healthy. 
# Otherwise, the cluster is unhealthy. An unhealthy status can occur when the cluster database is under extremely heavy load or if there is a configuration problem with a database on the cluster.
module "dpr_redshift_health_status_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_redshift_health_check ? true : false

  alarm_name          = "dpr-redshift-health-status"
  alarm_description   = "ATTENTION: DPR Redshift HealthStatus Monitor, Please investigate Redshift Errors !"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1 # Boolean
  threshold           = local.thrld_redshift_health_check
  period              = local.period_redshift_health_check

  namespace   = "AWS/Redshift"
  metric_name = "HealthStatus"
  statistic   = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}


## Monitoring AWS DMS tasks, https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Monitoring.html
# Alarm - "DMS Stop Monitor"
module "dpr_dms_stoptask_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_stop_check ? true : false

  alarm_name          = "dpr-dms-stop-task"
  alarm_description   = "ATTENTION: DPR DMS Replication Stop Monitor, Please investigate DMS Replication Task Errors !"
  comparison_operator = "GreaterThanThreshold"
  threshold           = local.thrld_dms_stop_check # Boolean
  period              = local.period_dms_stop_check
  evaluation_periods  = 1

  dimensions = {
    "Class"    = "None"
    "Resource" = "StopReplicationTask"
    "Service"  = "Database Migration Service"
    "Type"     = "API"
  }

  namespace   = "AWS/Usage"
  metric_name = "CallCount"
  statistic   = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Start Monitor"
module "dpr_dms_starttask_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_start_check ? true : false

  alarm_name          = "dpr-dms-start-task"
  alarm_description   = "ATTENTION: DPR DMS Replication Start Monitor, Please investigate DMS Replication Task Errors !"
  comparison_operator = "GreaterThanThreshold"
  threshold           = local.thrld_dms_start_check # Boolean
  period              = local.period_dms_start_check
  evaluation_periods  = 1

  dimensions = {
    "Class"    = "None"
    "Resource" = "StartReplicationTask"
    "Service"  = "Database Migration Service"
    "Type"     = "API"
  }

  namespace   = "AWS/Usage"
  metric_name = "CallCount"
  statistic   = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Network Transmit Throughput Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_network_transmit_throughput" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_network_trans_tp_check ? true : false

  alarm_name          = "dpr-dms-nomis-network-transmit-throughput"
  alarm_description   = "ATTENTION: DPR DMS Instance Network Throughput Monitor, Please investigate Network Transmit Throughput is below Threshold 1000 Bytes!"
  comparison_operator = "LessThanThreshold"
  period              = local.period_dms_network_trans_tp_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_network_trans_tp_check # 10 Bytes

  namespace   = "AWS/DMS"
  metric_name = "NetworkTransmitThroughput"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Network Receive Throughput Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_network_receive_throughput" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_network_rec_tp_check ? true : false

  alarm_name          = "dpr-dms-nomis-network-receive-throughput"
  alarm_description   = "ATTENTION: DPR DMS Instance Network Throughput Monitor, Please investigate Network Receive Throughput is below Threshold 10 Bytes!"
  comparison_operator = "LessThanThreshold"
  period              = local.period_dms_network_rec_tp_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_network_rec_tp_check # 10 Bytes

  namespace   = "AWS/DMS"
  metric_name = "NetworkReceiveThroughput"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

module "dpr_postgres_tickle_function_failure_alarm" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.create_postgres_tickle_function_failure_alarm

  alarm_name          = "dpr-postgres-tickle-function-failure"
  alarm_description   = "ATTENTION: DPR Postgres Tickle Function Failure, Please investigate!"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1 # Boolean
  threshold           = local.thrld_postgres_tickle_function_failure_alarm
  period              = local.period_postgres_tickle_function_failure_alarm
  unit                = "Count"

  treat_missing_data = "notBreaching"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Maximum"

  dimensions = {
    FunctionName = "dpr-postgres-tickle-function"
  }

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}
