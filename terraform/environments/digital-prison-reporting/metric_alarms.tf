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

# Alarm - "DMS CPU Utilization Monitor"
module "dpr_dms_cpu_utils_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_cpu_check ? true : false

  alarm_name          = "dpr-dms-nomis-cpu-utilization"
  alarm_description   = "ATTENTION: DPR DMS Instance CPU Monitor, Please investigate High CPU Utilization for DMS Instance !"
  comparison_operator = "GreaterThanThreshold"
  period              = local.period_dms_cpu_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_cpu_check # 80% CPU

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS FreeMemory Monitor"
module "dpr_dms_free_memory_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_freemem_check ? true : false

  alarm_name          = "dpr-dms-nomis-free-memory"
  alarm_description   = "ATTENTION: DPR DMS Instance FreeMemory Monitor, Please investigate FreeMemory is Below 1Gb DMS Instance !"
  comparison_operator = "LessThanThreshold"
  period              = local.period_dms_freemem_check 
  evaluation_periods  = 1
  threshold           = local.thrld_dms_freemem_check # 1Gb

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
  }

  namespace   = "AWS/DMS"
  metric_name = "FreeMemory"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS FreeableMemory Monitor"
module "dpr_dms_freeable_memory_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_freeablemem_check ? true : false

  alarm_name          = "dpr-dms-nomis-freeable-memory"
  alarm_description   = "ATTENTION: DPR DMS Instance Freeable Memory Monitor, Please investigate low FreeableMemory for Nomis DMS Instance !"
  comparison_operator = "LessThanOrEqualToThreshold"
  period              = local.period_dms_freeablemem_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_freeablemem_check # 1Gb

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
  }

  namespace   = "AWS/DMS"
  metric_name = "FreeableMemory"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# Alarm - "DMS SWAP Usage Monitor"
# https://repost.aws/knowledge-center/dms-swap-files-consuming-space
module "dpr_dms_swap_usage_check" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_swapusage_check ? true : false

  alarm_name          = "dpr-dms-nomis-swap-usage"
  alarm_description   = "ATTENTION: DPR DMS Instance SWAP Usage Monitor, Please investigate SWAP Usage is Above 0.75 Gb for DMS Instance!"
  comparison_operator = "GreaterThanThreshold"
  period              = local.period_dms_swapusage_check 
  evaluation_periods  = 1
  threshold           = local.thrld_dms_swapusage_check # 0.75Gb

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
  }

  namespace   = "AWS/DMS"
  metric_name = "SwapUsage"
  statistic   = "Average"

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

# DMS, CDCLatencySource
# The gap, in seconds, between the last event captured from the source endpoint and current system time stamp of the AWS DMS instance. 
# CDCLatencySource represents the latency between source and replication instance. 
# High CDCLatencySource means the process of capturing changes from source is delayed.
module "dpr_dms_cdc_source_latency" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_cdc_src_lat_check ? true : false

  alarm_name          = "dpr-dms-nomis-cdc-source-latency"
  alarm_description   = "ATTENTION: P1 Incident: DPR DMS CDC Source Latency, Please investigate CDC Source Latency for Oracle Nomis is greater than 60 mins !"
  comparison_operator = "GreaterThanThreshold"
  period              = local.period_dms_cdc_src_lat_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_cdc_src_lat_check # 60 mins

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
    "ReplicationTaskIdentifier"     = module.dms_nomis_ingestor.dms_replication_task_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CDCLatencySource"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# DMS, CDCLatencyTarget
# The gap, in seconds, between the first event timestamp waiting to commit on the target and the current timestamp of the AWS DMS instance. 
# Target latency is the difference between the replication instance server time and the oldest unconfirmed event id forwarded to a target component. 
module "dpr_dms_cdc_target_latency" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_cdc_targ_lat_check ? true : false

  alarm_name          = "dpr-dms-nomis-cdc-target-latency"
  alarm_description   = "ATTENTION: P1 Incident: DPR DMS CDC Target Latency, Please investigate CDC Target Latency for Oracle Nomis is greater than 60 mins !"
  comparison_operator = "GreaterThanThreshold"
  period              = local.period_dms_cdc_targ_lat_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_cdc_targ_lat_check # 60 mins

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
    "ReplicationTaskIdentifier"     = module.dms_nomis_ingestor.dms_replication_task_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CDCLatencyTarget"
  statistic   = "Average"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}

# DMS CDCIncomingChanges, 
# The total number of change events at a point-in-time that are waiting to be applied to the target. 
# Note that this is not the same as a measure of the transaction change rate of the source endpoint. 
# A large number for this metric usually indicates AWS DMS is unable to apply captured changes in a timely manner, 
# thus causing high target latency.
module "dpr_dms_cdc_incoming_events" {
  source              = "./modules/cw_alarm"
  create_metric_alarm = local.enable_cw_alarm && local.enable_dms_cdc_inc_events_check ? true : false

  alarm_name          = "dpr-dms-nomis-cdc-incoming-events"
  alarm_description   = "ATTENTION: P1 Incident: DPR DMS CDC Incoming Events Alert, Please investigate CDC Incoming Events are waiting to be applied for Oracle Nomis !"
  comparison_operator = "GreaterThanThreshold"
  period              = local.period_dms_cdc_inc_events_check
  evaluation_periods  = 1
  threshold           = local.thrld_dms_cdc_inc_events_check # 100 events 

  dimensions = {
    "ReplicationInstanceIdentifier" = module.dms_nomis_ingestor.dms_instance_name
    "ReplicationTaskIdentifier"     = module.dms_nomis_ingestor.dms_replication_task_name
  }

  namespace   = "AWS/DMS"
  metric_name = "CDCIncomingChanges"
  statistic   = "Maximum"

  alarm_actions = [module.notifications_sns.sns_topic_arn]
}
