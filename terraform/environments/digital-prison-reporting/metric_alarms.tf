## Redshift ##
# Alarm - "Redshift Health Status"
module "dpr_redshift_health_status_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-redshift-health-status"
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


## DMS ##
# Alarm - "DMS Stop Monitor"
module "dpr_dms_stoptask_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-stop-task"
  alarm_description   = "ATTENTION: DPR DMS Replication Stop Monitor, Please investigate DMS Replication Task Errors !"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 30
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

# Alarm - "DMS Start Monitor"
module "dpr_dms_starttask_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-start-task"
  alarm_description   = "ATTENTION: DPR DMS Replication Start Monitor, Please investigate DMS Replication Task Errors !"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 30
  evaluation_periods  = 1

  dimensions = {
    "Class"    = "None"
    "Resource" = "StartReplicationTask"
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

  alarm_name          = "dpr-dms-cpu-utilization"
  alarm_description   = "ATTENTION: DPR DMS Instance CPU Monitor, Please investigate High CPU Utilization for DMS Instance !"
  comparison_operator = "GreaterThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80

  namespace   = "AWS/DMS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS FreeMemory Monitor"
module "dpr_dms_free_memory_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-free-memory"
  alarm_description   = "ATTENTION: DPR DMS Instance FreeMemory Monitor, Please investigate FreeMemory is Below 1Gb DMS Instance !"
  comparison_operator = "LessThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1000000000

  namespace   = "AWS/DMS"
  metric_name = "FreeMemory"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS SWAP Usage Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_swap_usage_check" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-swap-usage"
  alarm_description   = "ATTENTION: DPR DMS Instance SWAP Usage Monitor, Please investigate SWAP Usage is Above 0.75 Gb for DMS Instance!"
  comparison_operator = "GreaterThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 750000000

  namespace   = "AWS/DMS"
  metric_name = "SwapUsage"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Network Transmit Throughput Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_network_transmit_throughput" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-network-transmit-throughput"
  alarm_description   = "ATTENTION: DPR DMS Instance Network Throughput Monitor, Please investigate Network Transmit Throughput is below Threshold 1000 Bytes!"
  comparison_operator = "LessThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10 # 10 Bytes

  namespace   = "AWS/DMS"
  metric_name = "NetworkTransmitThroughput"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS Network Receive Throughput Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_network_receive_throughput" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-network-receive-throughput"
  alarm_description   = "ATTENTION: DPR DMS Instance Network Throughput Monitor, Please investigate Network Receive Throughput is below Threshold 10 Bytes!"
  comparison_operator = "LessThanThreshold"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10 # 10 Bytes

  namespace   = "AWS/DMS"
  metric_name = "NetworkReceiveThroughput"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

module "dpr_dms_cdc_source_latency" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-cdc-source-latency"
  alarm_description   = "ATTENTION: P1 Incident: DPR DMS CDC Source Latency, Please investigate CDC Source Latency for Oracle Nomis is greater than 60 mins !"
  comparison_operator = "GreaterThanThreshold"
  period              = 900
  evaluation_periods  = 1
  threshold           = 3600 # 60 mins

  dimensions                = {
    - "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
    - "ReplicationTaskIdentifier"     = module.dms_nomis_ingestor.dms_replication_task_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CDCLatencySource"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

module "dpr_dms_cdc_target_latency" {
  source = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm

  alarm_name          = "dpr-dms-cdc-target-latency"
  alarm_description   = "ATTENTION: P1 Incident: DPR DMS CDC Target Latency, Please investigate CDC Target Latency for Oracle Nomis is greater than 60 mins !"
  comparison_operator = "GreaterThanThreshold"
  period              = 900
  evaluation_periods  = 1
  threshold           = 3600 # 60 mins

  dimensions                = {
    - "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
    - "ReplicationTaskIdentifier"     = module.dms_nomis_ingestor.dms_replication_task_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CDCLatencyTarget"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}