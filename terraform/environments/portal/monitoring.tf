locals {
  dashboard_name            = "${local.application_name}-${local.environment}-application-Dashboard"
  cpu_alarm_threshold       = 85 # in percentage
  status_alarm_threshold    = 1
  memory_alarm_threshold    = 80          # in percentage
  swapspace_alarm_threshold = 50000000000 # in Bytes
  diskspace_alarm_threshold = 80          # in percentage
  mserver_alarm_threshold   = 80          # in percentage

  alarms_1 = {
    oam1 = {
      instance_id = aws_instance.oam_instance_1.id
    },
    ohs1 = {
      instance_id = aws_instance.ohs_instance_1.id
    },
    oim1 = {
      instance_id = aws_instance.oim_instance_1.id
    },
    idm1 = {
      instance_id = aws_instance.idm_instance_1.id
    }
  }
  alarms_2 = {
    oam2 = {
      instance_id = try(aws_instance.oam_instance_2[0].id, "")
    },
    ohs2 = {
      instance_id = try(aws_instance.ohs_instance_2[0].id, "")
    },
    oim2 = {
      instance_id = try(aws_instance.oim_instance_2[0].id, "")
    },
    idm2 = {
      instance_id = try(aws_instance.idm_instance_2[0].id, "")
    }
  }

  alarms_list = local.environment == "production" ? merge(local.alarms_1, local.alarms_2) : local.alarms_1
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-CPU-high-threshold-alarm"
  alarm_description   = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = each.value.instance_id
  }
  evaluation_periods = "5"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.cpu_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-CPU-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "status_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-status-check-failure-alarm"
  alarm_description   = "If a status check failure occurs on an instance, please investigate. http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = each.value.instance_id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.status_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-status-check-failure-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-memory-usage-alarm"
  alarm_description   = "If the memory use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = each.value.instance_id
  }
  evaluation_periods = "5"
  metric_name        = "mem_used_percent"
  namespace          = "CWAgent"
  period             = "60"
  statistic          = "Average"
  threshold          = local.memory_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-memory-usage-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "swapspace_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-swap-usage-alarm"
  alarm_description   = "If the memory use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = each.value.instance_id
  }
  evaluation_periods = "5"
  metric_name        = "swap_used"
  namespace          = "CWAgent"
  period             = "60"
  statistic          = "Average"
  threshold          = local.swapspace_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-swap-usage-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "diskspace_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-root-vol-disk-usage-alarm"
  alarm_description   = "If the disk space use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    path       = "/"
    InstanceId = each.value.instance_id
    fstype     = "xfs"
  }
  evaluation_periods = "5"
  metric_name        = "disk_used_percent"
  namespace          = "CWAgent"
  period             = "60"
  statistic          = "Average"
  threshold          = local.diskspace_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-root-vol-disk-usage-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "mserver_alarm" {
  for_each = {
    for k, v in local.alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-mserver-disk-usage-alarm"
  alarm_description   = "If the disk space use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    path       = "/IDAM/product/runtime/Domain/mserver"
    InstanceId = each.value.instance_id
    fstype     = "ext4"
  }
  evaluation_periods = "5"
  metric_name        = "disk_used_percent"
  namespace          = "CWAgent"
  period             = "60"
  statistic          = "Average"
  threshold          = local.mserver_alarm_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${each.key}-mserver-disk-usage-alarm"
    }
  )
}


data "template_file" "dashboard_prod" {
  count    = local.environment == "production" ? 1 : 0
  template = file("${path.module}/dashboard_prod.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region = local.aws_region
    # elb_5xx_alarm_arn               = aws_cloudwatch_metric_alarm.ApplicationELB5xxError.arn
    # elb_4xx_alarm_arn               = aws_cloudwatch_metric_alarm.ApplicationELB4xxError.arn
    # elb_response_time_alarm_arn     = aws_cloudwatch_metric_alarm.TargetResponseTime.arn
    # iadb_cpu_alarm_arn              = aws_cloudwatch_metric_alarm.RDS1CPUoverThreshold.arn
    # iadb_read_latency_alarm_arn     = aws_cloudwatch_metric_alarm.RDS1ReadLataencyOverThreshold.arn
    # iadb_write_latency_alarm_arn    = aws_cloudwatch_metric_alarm.RDS1WriteLataencyOverThreshold.arn
    # igdb_cpu_alarm_arn              = aws_cloudwatch_metric_alarm.RDS2CPUoverThreshold.arn
    # igdb_read_latency_alarm_arn     = aws_cloudwatch_metric_alarm.RDS2ReadLataencyOverThreshold.arn
    # igdb_write_latency_alarm_arn    = aws_cloudwatch_metric_alarm.RDS2WriteLataencyOverThreshold.arn
    # oim1_cpu_alarm_arn              = aws_cloudwatch_metric_alarm.cpu_alarm["oim_instance_1"].arn
    # oim1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["oim_instance_1"].arn
    # oim2_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["oim_instance_2"].arn
    # oam1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["oam_instance_1"].arn
    # oam2_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["oam_instance_2"].arn
    # idm1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["idm_instance_1"].arn
    # idm2_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["idm_instance_2"].arn
    # ohs1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["ohs_instance_1"].arn
    # ohs2_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["ohs_instance_2"].arn
    # oim2_diskspace_alarm_arn        = aws_cloudwatch_metric_alarm.diskspace_alarm["oim_instance_2"].arn
    # oim2_swapspace_alarm_arn        = aws_cloudwatch_metric_alarm.swapspace_alarm["oim_instance_2"].arn
  }
}

data "template_file" "dashboard_nonprod" {
  count    = local.environment != "production" ? 1 : 0
  template = file("${path.module}/dashboard_nonprod_temp.tpl") # TODO Update this to dashboard_nonprod.tpl once all relevant resources are created

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region                   = local.aws_region
    elb_5xx_alarm_arn            = aws_cloudwatch_metric_alarm.ext_lb_origin_5xx.arn
    elb_4xx_alarm_arn            = aws_cloudwatch_metric_alarm.ext_lb_origin_4xx.arn
    elb_response_time_alarm_arn  = aws_cloudwatch_metric_alarm.ext_lb_target_response_time.arn
    iadb_cpu_alarm_arn           = aws_cloudwatch_metric_alarm.iadb_rds_cpu.arn
    iadb_read_latency_alarm_arn  = aws_cloudwatch_metric_alarm.iadb_rds_read_latency.arn
    iadb_write_latency_alarm_arn = aws_cloudwatch_metric_alarm.iadb_rds_write_latency.arn
    igdb_cpu_alarm_arn           = aws_cloudwatch_metric_alarm.igdb_rds_cpu.arn
    igdb_read_latency_alarm_arn  = aws_cloudwatch_metric_alarm.igdb_rds_read_latency.arn
    igdb_write_latency_alarm_arn = aws_cloudwatch_metric_alarm.igdb_rds_write_latency.arn
    oim1_cpu_alarm_arn           = aws_cloudwatch_metric_alarm.cpu_alarm["oim1"].arn
    oim1_memory_alarm_arn        = aws_cloudwatch_metric_alarm.memory_alarm["oim1"].arn
    oam1_memory_alarm_arn        = aws_cloudwatch_metric_alarm.memory_alarm["oam1"].arn
    idm1_memory_alarm_arn        = aws_cloudwatch_metric_alarm.memory_alarm["idm1"].arn
    ohs1_memory_alarm_arn        = aws_cloudwatch_metric_alarm.memory_alarm["ohs1"].arn
  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = local.dashboard_name
  dashboard_body = local.environment == "production" ? data.template_file.dashboard_prod[0].rendered : data.template_file.dashboard_nonprod[0].rendered
}
