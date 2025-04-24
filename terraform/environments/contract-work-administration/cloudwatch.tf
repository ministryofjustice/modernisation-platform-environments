resource "aws_cloudwatch_metric_alarm" "efs_data_write" {

  alarm_name          = "${local.application_name_short}-${local.environment}-efs-data-write"
  alarm_description   = "EFS Data Write IO Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.cwa.id
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "DataWriteIOBytes"
  namespace          = "AWS/EFS"
  period             = local.application_data.accounts[local.environment].alert_period
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "DataReadIOBytes"
  namespace          = "AWS/EFS"
  period             = local.application_data.accounts[local.environment].alert_period
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = local.application_data.accounts[local.environment].alert_period
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
  period             = local.application_data.accounts[local.environment].alert_period
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "RequestCount"
  namespace          = "AWS/ApplicationELB"
  period             = local.application_data.accounts[local.environment].alert_period
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

resource "aws_cloudwatch_metric_alarm" "elb_unhealthy_hosts_count" {

  alarm_name          = "${local.application_name_short}-${local.environment}-elb-unhealthy-hosts-count"
  alarm_description   = "CWA ELB Healthy Hosts less than Threshold"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    TargetGroup  = aws_lb_target_group.external.arn_suffix
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = 1
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-elb-unhealthy-hosts-count"
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = local.application_data.accounts[local.environment].alert_period
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
  count               = contains(["development", "test"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-ec2-status-check"
  alarm_description   = "App2 EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "StatusCheckFailed_Instance"
  namespace          = "AWS/EC2"
  period             = local.application_data.accounts[local.environment].alert_period
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = local.application_data.accounts[local.environment].alert_period
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = local.application_data.accounts[local.environment].alert_period
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

########################################
### (Manual)
########################################


resource "aws_cloudwatch_metric_alarm" "database_ec2_memory" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-memory"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId   = aws_instance.database.id
    ImageId      = aws_instance.database.ami
    InstanceType = aws_instance.database.instance_type
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "mem_used_percent"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_ec2_memory_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
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
    InstanceId   = aws_instance.database.id
    ImageId      = aws_instance.database.ami
    InstanceType = aws_instance.database.instance_type
    interface    = local.ec2_network_interface
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "net_err_in"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].database_packet_errors_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-rx-packet-errors"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_rx_packet_dropped" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-rx-packet-dropped"
  alarm_description   = "Number of Dropped RX Packets Over Threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId   = aws_instance.database.id
    ImageId      = aws_instance.database.ami
    InstanceType = aws_instance.database.instance_type
    interface    = local.ec2_network_interface
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "net_drop_in"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].database_packet_dropped_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-rx-packet-dropped"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_tx_packet_errors" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-tx-packet-errors"
  alarm_description   = "Number of TX Packet Errors Over Threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId   = aws_instance.database.id
    ImageId      = aws_instance.database.ami
    InstanceType = aws_instance.database.instance_type
    interface    = local.ec2_network_interface
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "net_err_out"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].database_packet_errors_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-tx-packet-errors"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_tx_packet_dropped" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-tx-packet-dropped"
  alarm_description   = "Number of Dropped tx Packets Over Threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId   = aws_instance.database.id
    ImageId      = aws_instance.database.ami
    InstanceType = aws_instance.database.instance_type
    interface    = local.ec2_network_interface
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "net_drop_out"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].database_packet_dropped_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-tx-packet-dropped"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oradata_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oradata-read"
  alarm_description   = "EBS Oradata Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oradata"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oradata_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_oradata"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oradata-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraredo_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraredo-read"
  alarm_description   = "EBS oraredo Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraredo"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraredo_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_oraredo"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraredo-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraarch_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraarch-read"
  alarm_description   = "EBS oraarch Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraarch"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraarch_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_oraarch"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraarch-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oratmp_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oratmp-read"
  alarm_description   = "EBS oratmp Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oratmp"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oratmp_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_oratmp"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oratmp-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oracle_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oracle-read"
  alarm_description   = "EBS oracle Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oracle"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oracle_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_oracle"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oracle-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_root_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-root-read"
  alarm_description   = "EBS root Volume - Reads too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/"
    ImageId      = aws_instance.database.ami
    InstanceId   = aws_instance.database.id
    InstanceType = aws_instance.database.instance_type
    device       = local.root_device_name
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_reads_root"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-root-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraredo_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraredo-diskspace"
  alarm_description   = "EBS Oraredo Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraredo"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraredo_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_oraredo"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
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
    path         = "/CWA/oradata"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oradata_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_oradata"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
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
    path         = "/CWA/oratmp"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oratmp_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_oratmp"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
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

resource "aws_cloudwatch_metric_alarm" "database_oraarch_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraarch-diskspace"
  alarm_description   = "EBS oraarch Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraarch"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraarch_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_oraarch"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraarch-diskspace"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oracle_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oracle-diskspace"
  alarm_description   = "EBS oracle Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oracle"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oracle_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_oracle"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oracle-diskspace"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_root_diskspace" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-root-diskspace"
  alarm_description   = "EBS root Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = local.root_device_name
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "disk_used_percent_root"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_diskspace_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-root-diskspace"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraarch_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraarch-writes"
  alarm_description   = "EBS Oraarch Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraarch"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraarch_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_oraarch"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraarch-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oratmp_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oratmp-writes"
  alarm_description   = "EBS oratmp Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oratmp"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oratmp_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_oratmp"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oratmp-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oradata_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oradata-writes"
  alarm_description   = "EBS oradata Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oradata"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oradata_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_oradata"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oradata-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oraredo_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oraredo-writes"
  alarm_description   = "EBS oraredo Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oraredo"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oraredo_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_oraredo"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oraredo-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oracle_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oracle-writes"
  alarm_description   = "EBS oracle Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/CWA/oracle"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = "/dev/xvd${local.oracle_device_name_letter}"
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_oracle"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oracle-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_root_writes" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-root-writes"
  alarm_description   = "EBS root Volume - Writes too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    path         = "/"
    InstanceId   = aws_instance.database.id
    ImageId      = local.application_data.accounts[local.environment].db_ami_id
    InstanceType = aws_instance.database.instance_type
    device       = local.root_device_name
    fstype       = "ext4"
  }
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "volume_writes_root"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_read_write_ops_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-root-writes"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oradata_queue_length" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-oradata-queue-length"
  alarm_description   = "Oradata Volume EBS Queue Length is High"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    VolumeId = aws_ebs_volume.oradata.id
  }
  evaluation_periods = 1
  metric_name        = "VolumeQueueLength"
  namespace          = "AWS/EBS"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_oradata_queue_length_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-oradata-queue-length"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app1_f60srvm_process" {

  alarm_name          = "${local.application_name_short}-${local.environment}-app1-f60srvm-process"
  alarm_description   = ""
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app1.id
  }
  evaluation_periods = 1
  metric_name        = "f60srvm_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app1-f60srvm-process"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app1_cwa_process" {

  alarm_name          = "${local.application_name_short}-${local.environment}-app1-cwa-process"
  alarm_description   = "APPS_CWA Process has stopped"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app1.id
  }
  evaluation_periods = 1
  metric_name        = "apps_cwa_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app1-cwa-process"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app1_apache_process" {

  alarm_name          = "${local.application_name_short}-${local.environment}-app1-apache-process"
  alarm_description   = "Apache Process has stopped"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app1.id
  }
  evaluation_periods = 1
  metric_name        = "apache_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app1-apache-process"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app2_f60srvm_process" {
  count               = contains(["development", "test"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-f60srvm-process"
  alarm_description   = ""
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = 1
  metric_name        = "f60srvm_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app2-f60srvm-process"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app2_cwa_process" {
  count               = contains(["development", "test"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-cwa-process"
  alarm_description   = "APPS_CWA Process has stopped"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = 1
  metric_name        = "apps_cwa_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app2-cwa-process"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app2_apache_process" {
  count               = contains(["development", "test"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-apache-process"
  alarm_description   = "Apache Process has stopped"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = 1
  metric_name        = "apache_process"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Sum"
  threshold          = 0
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app2-apache-process"
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
  evaluation_periods = local.application_data.accounts[local.environment].alert_eval_period
  metric_name        = "swap_used_percentage"
  namespace          = "CustomScript"
  period             = local.application_data.accounts[local.environment].alert_period
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_ec2_swap_alarm_threshold
  alarm_actions      = [aws_sns_topic.cwa.arn]
  ok_actions         = [aws_sns_topic.cwa.arn]
  treat_missing_data = "missing"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-swap"
    }
  )
}

################################
### CloudWatch Dashboard
################################

data "template_file" "dashboard_ha" {
  count    = contains(["development", "test"], local.environment) ? 0 : 1
  template = file("${path.module}/dashboard_ha.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region = "eu_west_2"
  }
}

data "template_file" "dashboard_no_ha" {
  count    = contains(["development", "test"], local.environment) ? 1 : 0
  template = file("${path.module}/dashboard_no_ha.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region                       = "eu-west-2"
    dashboard_refresh_period         = 60
    database_instance_id             = aws_instance.database.id
    database_cpu_alarm               = aws_cloudwatch_metric_alarm.database_cpu.arn
    database_memory_alarm            = aws_cloudwatch_metric_alarm.database_ec2_memory.arn
    database_oradata_diskspace_alarm = aws_cloudwatch_metric_alarm.database_oradata_diskspace.arn
    database_oraarch_diskspace_alarm = aws_cloudwatch_metric_alarm.database_oraarch_diskspace.arn
    database_oratmp_diskspace_alarm  = aws_cloudwatch_metric_alarm.database_oratmp_diskspace.arn
    database_oraredo_diskspace_alarm = aws_cloudwatch_metric_alarm.database_oraredo_diskspace.arn
    database_oracle_diskspace_alarm  = aws_cloudwatch_metric_alarm.database_oracle_diskspace.arn
    database_root_diskspace_alarm    = aws_cloudwatch_metric_alarm.database_root_diskspace.arn
    database_rx_packet_dropped_alarm = aws_cloudwatch_metric_alarm.database_rx_packet_dropped.arn
    database_tx_packet_dropped_alarm = aws_cloudwatch_metric_alarm.database_tx_packet_dropped.arn
    database_rx_packet_errors_alarm  = aws_cloudwatch_metric_alarm.database_rx_packet_errors.arn
    database_tx_packet_errors_alarm  = aws_cloudwatch_metric_alarm.database_tx_packet_errors.arn
    database_oradata_read_alarm      = aws_cloudwatch_metric_alarm.database_oradata_read.arn
    database_oraarch_read_alarm      = aws_cloudwatch_metric_alarm.database_oraarch_read.arn
    database_oratmp_read_alarm       = aws_cloudwatch_metric_alarm.database_oratmp_read.arn
    database_oraredo_read_alarm      = aws_cloudwatch_metric_alarm.database_oraredo_read.arn
    database_oracle_read_alarm       = aws_cloudwatch_metric_alarm.database_oracle_read.arn
    database_root_read_alarm         = aws_cloudwatch_metric_alarm.database_root_read.arn
    database_oradata_writes_alarm    = aws_cloudwatch_metric_alarm.database_oradata_writes.arn
    database_oraarch_writes_alarm    = aws_cloudwatch_metric_alarm.database_oraarch_writes.arn
    database_oratmp_writes_alarm     = aws_cloudwatch_metric_alarm.database_oratmp_writes.arn
    database_oraredo_writes_alarm    = aws_cloudwatch_metric_alarm.database_oraredo_writes.arn
    database_oracle_writes_alarm     = aws_cloudwatch_metric_alarm.database_oracle_writes.arn
    database_root_writes_alarm       = aws_cloudwatch_metric_alarm.database_root_writes.arn
    database_status_check_alarm      = aws_cloudwatch_metric_alarm.database_ec2_status_check.arn
    cm_status_check_alarm            = aws_cloudwatch_metric_alarm.cm_ec2_status_check.arn
    app1_status_check_alarm          = aws_cloudwatch_metric_alarm.app1_ec2_status_check.arn
    elb_request_count_alarm          = aws_cloudwatch_metric_alarm.elb_request_count.arn
    efs_data_read_alarm              = aws_cloudwatch_metric_alarm.efs_data_read.arn
    efs_data_write_alarm             = aws_cloudwatch_metric_alarm.efs_data_write.arn
    database_ec2_swap_alarm          = aws_cloudwatch_metric_alarm.database_ec2_swap.arn

  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${upper(local.application_name_short)}-Monitoring-Dashboard"
  dashboard_body = contains(["development", "test"], local.environment) ? data.template_file.dashboard_no_ha[0].rendered : data.template_file.dashboard_ha[0].rendered
}