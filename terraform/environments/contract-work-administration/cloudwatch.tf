resource "aws_cloudwatch_metric_alarm" "efs_data_write" {

  alarm_name          = "${local.application_name_short}-${local.environment}-efs-data-write"
  alarm_description   = "EFS Data Write IO Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.cwa.id
  }
  evaluation_periods = "5"
  metric_name        = "DataWriteIOBytes"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].efs_data_write_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-efs-data-write"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "efs_data_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-efs-data-read"
  alarm_description   = "EFS Data Read IO Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.cwa.id
  }
  evaluation_periods = "5"
  metric_name        = "DataReadIOBytes"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].efs_data_read_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-efs-data-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-cpu-alarm"
  alarm_description   = "The average CPU utilization is too high for the database instance"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_cpu_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-cpu-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "elb_target_response_time" {

  alarm_name          = "${local.application_name_short}-${local.environment}-elb-target-response-time"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if response is longer than 1s."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "1"
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = 60
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].elb_target_response_time_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-elb-target-response-time"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "elb_request_count" {

  alarm_name          = "${local.application_name_short}-${local.environment}-elb-request-count"
  alarm_description   = "ELB Request Count Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "RequestCount"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].elb_request_count_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-elb-request-count"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app1_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-app1-ec2-status-check"
  alarm_description   = "App1 EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.app1.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].status_check_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app2_ec2_status_check" {
  count               = contains(["development", "testing"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-ec2-status-check"
  alarm_description   = "App2 EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed_Instance"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].status_check_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "cm_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-concurrent-manager-ec2-status-check"
  alarm_description   = "Concurrent Manager EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.concurrent_manager.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].status_check_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-concurrent-manager-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-status-check"
  alarm_description   = "Database EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].status_check_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_ec2_swap" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-swap"
  alarm_description   = "Database EC2 Instance Swap Used Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "SwapUsed"
  namespace          = "System/Linux"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_ec2_swap_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  #   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-swap"
    }
  )
}


########################################
### (Manual)
########################################


resource "aws_cloudwatch_metric_alarm" "database_ec2_memory" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-memory"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "mem_used_percent"
  namespace          = "CustomScript"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_ec2_memory_alarm_threshold
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "missing"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-memory"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_rx_packet_errors" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-rx-packet-errors"
  alarm_description   = "Number of RX Packet Errors Over Threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "net_err_in"
  namespace          = "CustomScript"
  period             = "300"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_rx_packet_errors_alarm_threshold
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "missing"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-rx-packet-errors"
    }
  )
}


resource "aws_cloudwatch_metric_alarm" "database_oradata_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oradata-read"
  alarm_description   = "EBS Oradata Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path = "/CWA/oradata"
    ImageId = aws_instance.database.ami
    InstanceId = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device = "/dev/xvd${local.oradata_device_name_letter}"
    fstype = "ext4"
  }
  evaluation_periods = "5"
  metric_name        = "volume_reads_oradata"
  namespace          = "CustomScript"
  period             = "300"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_oradata_read_alarm_threshold
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "missing"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oradata-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraredo_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraredo-diskspace"
  alarm_description   = "EBS Oraredo Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path = "/CWA/oraredo"
    InstanceId = aws_instance.database.id
    ImageId = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device = "/dev/xvd${local.oraredo_device_name_letter}"
    fstype = "ext4"
  }
  evaluation_periods = "5"
  metric_name        = "disk_used_percent_oraredo"
  namespace          = "CustomScript"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraredo-diskspace"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oradata_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oradata-diskspace"
  alarm_description   = "EBS Oradata Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path = "/CWA/oradata"
    InstanceId = aws_instance.database.id
    ImageId = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device = "/dev/xvd${local.oradata_device_name_letter}"
    fstype = "ext4"
  }
  evaluation_periods = "5"
  metric_name        = "disk_used_percent_oradata"
  namespace          = "CustomScript"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oradata-diskspace"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oratmp_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oratmp-diskspace"
  alarm_description   = "EBS Oratmp Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path = "/CWA/oratmp"
    InstanceId = aws_instance.database.id
    ImageId = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device = "/dev/xvd${local.oratmp_device_name_letter}"
    fstype = "ext4"
  }
  evaluation_periods = "5"
  metric_name        = "disk_used_percent_oratmp"
  namespace          = "CustomScript"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oratmp-diskspace"
    }
  )
}

# resource "aws_cloudwatch_metric_alarm" "" {

#   alarm_name          = "${local.application_name_short}-${local.environment}-"
#   alarm_description   = ""
#   comparison_operator = ""
#   dimensions = {
#     InstanceId = aws_instance.database.id
#   }
#   evaluation_periods = ""
#   metric_name        = ""
#   namespace          = ""
#   period             = ""
#   statistic          = ""
#   threshold          = local.application_data.accounts[local.environment].database_oradata_read_alarm_threshold
#   alarm_actions      = [aws_sns_topic.cwa.arn]
#   ok_actions         = [aws_sns_topic.cwa.arn]
#   treat_missing_data = ""
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name_short}-${local.environment}-"
#     }
#   )
# }



################################
### CloudWatch Dashboard
################################

data "template_file" "dashboard_ha" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  template = file("${path.module}/dashboard_ha.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region = "eu_west_2"
  }
}

data "template_file" "dashboard_no_ha" {
  count    = contains(["development", "testing"], local.environment) ? 1 : 0
  template = file("${path.module}/dashboard_no_ha.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region                  = "eu-west-2"
    dashboard_refresh_period    = 60
    database_instance_id        = aws_instance.database.id
    database_cpu_alarm          = aws_cloudwatch_metric_alarm.database_cpu.arn
    database_status_check_alarm = aws_cloudwatch_metric_alarm.database_ec2_status_check.arn
    cm_status_check_alarm       = aws_cloudwatch_metric_alarm.cm_ec2_status_check.arn
    app1_status_check_alarm     = aws_cloudwatch_metric_alarm.app1_ec2_status_check.arn
    elb_request_count_alarm     = aws_cloudwatch_metric_alarm.elb_request_count.arn
    efs_data_read_alarm         = aws_cloudwatch_metric_alarm.efs_data_read.arn
    efs_data_write_alarm        = aws_cloudwatch_metric_alarm.efs_data_write.arn
  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${upper(local.application_name_short)}-Monitoring-Dashboard"
  dashboard_body = contains(["development", "testing"], local.environment) ? data.template_file.dashboard_no_ha[0].rendered : data.template_file.dashboard_ha[0].rendered
}