locals {
  dashboard_name                 = "${local.application_name}-${local.environment}-application-Dashboard"

  cpu_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      cpu_alarm_threshold = 70
      dimensions = {
        InstanceId = aws_instance.oam_instance_1.id
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      cpu_alarm_threshold = 70
      dimensions = {
        InstanceId = aws_instance.ohs1.id
      }
    }
  }
  cpu_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      cpu_alarm_threshold = 70
      dimensions = {
        InstanceId = "alice"
        # InstanceId = aws_instance.oam_app_instance_2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_2 = {
      service_name          = "oim_2"
      cpu_alarm_threshold = 70
      dimensions = {
        InstanceId = "bob"
        # InstanceId = aws_instance.ohs1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  status_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      status_alarm_threshold = 1
      dimensions = {
        InstanceId = aws_instance.oam_instance_1.id
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      status_alarm_threshold = 1
      dimensions = {
        InstanceId = aws_instance.ohs1.id
      }
    }
  }
  status_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      status_alarm_threshold = 1
      dimensions = {
        InstanceId = "alice"
        # InstanceId = aws_instance.oam_app_instance_2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  memory_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      memory_alarm_threshold = 70
      dimensions = {
        InstanceId = aws_instance.oam_instance_1.id
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      memory_alarm_threshold = 70
      dimensions = {
        InstanceId = aws_instance.ohs1.id
      }
    }
  }
  memory_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      memory_alarm_threshold = 80
      dimensions = {
        InstanceId = "alice"
        # InstanceId = aws_instance.oam_app_instance_2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_2 = {
      service_name          = "ohs_2"
      memory_alarm_threshold = 70
      dimensions = {
        InstanceId = "bob"
        # InstanceId = aws_instance.ohs2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  swapspace_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      swapspace_alarm_threshold = 50
      dimensions = {
        InstanceId = aws_instance.oam_instance_1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      swapspace_alarm_threshold = 50
      dimensions = {
        InstanceId = aws_instance.ohs1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  swapspace_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      swapspace_alarm_threshold = 50
      dimensions = {
        InstanceId = "alice"
        # InstanceId = aws_instance.oam_app_instance_2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_2 = {
      service_name          = "ohs_2"
      swapspace_alarm_threshold = 50
      dimensions = {
        InstanceId = "bob"
        # InstanceId = aws_instance.ohs2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  diskspace_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      diskspace_alarm_threshold = 80
      dimensions = {
        MountPath = "/"
        Filesystem = "/dev/nvme0n1p2"
        InstanceId = aws_instance.oam_instance_1.id
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      diskspace_alarm_threshold = 80
      dimensions = {
        MountPath = "/"
        Filesystem = "/dev/nvme0n1p2"
        InstanceId = aws_instance.ohs1.id
      }
    }
  }
  diskspace_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      diskspace_alarm_threshold = 80
      dimensions = {
        InstanceId = "alice"
        MountPath = "/"
        Filesystem = "/dev/nvme0n1p2"
        # InstanceId = aws_instance.oam_instance_1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_2 = {
      service_name          = "ohs_2"
      diskspace_alarm_threshold = 80
      dimensions = {
        InstanceId = "alice"
        MountPath = "/"
        Filesystem = "/dev/nvme0n1p2"
        # InstanceId = aws_instance.ohs2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  mserver_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      mserver_alarm_threshold = 80
      dimensions = {
        MountPath = "/IDAM/product/runtime/Domain/mserver"
        Filesystem = "/dev/nvme4n1"
        InstanceId = aws_instance.oam_instance_1.id
      }
    },
    ohs_instance_1 = {
      service_name          = "ohs_1"
      mserver_alarm_threshold = 80
      dimensions = {
        MountPath = "/IDAM/product/runtime/Domain/mserver"
        Filesystem = "/dev/nvme4n1"
        InstanceId = aws_instance.ohs1.id
      }
    }
  }
  mserver_alarms_2 = {
    oam_instance_2 = {
      service_name          = "oam_2"
      mserver_alarm_threshold = 80
      dimensions = {
        InstanceId = "alice"
        MountPath = "/IDAM/product/runtime/Domain/mserver"
        Filesystem = "/dev/nvme1n1"
        # InstanceId = aws_instance.oam_instance_1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    },
    ohs_instance_2 = {
      service_name          = "ohs_2"
      mserver_alarm_threshold = 80
      dimensions = {
        InstanceId = "alice"
        MountPath = "/IDAM/product/runtime/Domain/mserver"
        Filesystem = "/dev/nvme1n1"
        # InstanceId = aws_instance.ohs2.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }
  aserver_alarms_1 = {
    oam_instance_1 = {
      service_name          = "oam_1"
      aserver_alarm_threshold = 80
      dimensions = {
        MountPath = "/IDAM/product/runtime/Domain/aserver"
        Filesystem = "/dev/nvme1n1"
        InstanceId = aws_instance.oam_instance_1.id # TODO This needs updating when the OAM EC2 instance is built
      }
    }
  }

  cpu_alarms_list = local.environment == "production" ? merge(local.cpu_alarms_1, local.cpu_alarms_2) : local.cpu_alarms_1
  status_alarms_list = local.environment == "production" ? merge(local.status_alarms_1, local.status_alarms_2) : local.status_alarms_1
  memory_alarms_list = local.environment == "production" ? merge(local.memory_alarms_1, local.memory_alarms_2) : local.memory_alarms_1
  swapspace_alarms_list = local.environment == "production" ? merge(local.swapspace_alarms_1, local.swapspace_alarms_2) : local.swapspace_alarms_1
  diskspace_alarms_list = local.environment == "production" ? merge(local.diskspace_alarms_1, local.diskspace_alarms_2) : local.diskspace_alarms_1
  mserver_alarms_list = local.environment == "production" ? merge(local.mserver_alarms_1, local.mserver_alarms_2) : local.mserver_alarms_1

}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  for_each = {
    for k, v in local.cpu_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-CPU-high-threshold-alarm"
  alarm_description   = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.cpu_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "status_alarm" {
  for_each = {
    for k, v in local.status_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-status-check-failure-alarm"
  alarm_description   = "If a status check failure occurs on an instance, please investigate. http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.status_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  for_each = {
    for k, v in local.memory_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-memory-usage-alarm"
  alarm_description   = "If the memory use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.memory_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "swapspace_alarm" {
  for_each = {
    for k, v in local.swapspace_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-swap-usage-alarm"
  alarm_description   = "If the memory use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "SwapUsed"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.swapspace_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "diskspace_alarm" {
  for_each = {
    for k, v in local.diskspace_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-root-vol-disk-usage-alarm"
  alarm_description   = "If the disk space use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.diskspace_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "mserver_alarm" {
  for_each = {
    for k, v in local.mserver_alarms_list : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-mserver-disk-usage-alarm"
  alarm_description   = "If the disk space use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.mserver_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "aserver_alarm" {
  for_each = {
    for k, v in local.aserver_alarms_1 : k => v
  }

  alarm_name          = "${local.application_name}-${local.environment}-${each.value.service_name}-aserver-disk-usage-alarm"
  alarm_description   = "If the disk space use exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions
  evaluation_periods  = "5"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.aserver_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = "breaching"
}





data "template_file" "dashboard_prod" {
  count = local.environment == "production" ? 1 : 0
  template = file("${path.module}/dashboard_prod.tpl")

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region                      = local.aws_region
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
  count = local.environment != "production" ? 1 : 0
  template = file("${path.module}/dashboard_nonprod_temp.tpl") # TODO Update this to dashboard_nonprod.tpl once all relevant resources are created

  # TODO Update the local variables to reference the correct alarms once they are created
  vars = {
    aws_region                      = local.aws_region
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
    oam1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["oam_instance_1"].arn
    # idm1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["idm_instance_1"].arn
    ohs1_memory_alarm_arn           = aws_cloudwatch_metric_alarm.memory_alarm["ohs_instance_1"].arn
  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = local.dashboard_name
  dashboard_body = local.environment == "production" ? data.template_file.dashboard_prod[0].rendered : data.template_file.dashboard_nonprod[0].rendered
}
