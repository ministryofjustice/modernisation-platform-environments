resource "aws_cloudwatch_dashboard" "iaps" {
  dashboard_name = local.application_name
  dashboard_body = jsonencode(local.dashboard_body)
}

locals {
  cloudwatch_period = local.environment == "production" ? 300 : 60

  dashboard_body = {
    widgets = [
      local.IapsEC2CPUUtilWidget,
      local.IapsMemUtilWidget,
      local.IapsEC2DiskUtilWidget,
      local.IapsErrorLogWidget,
      local.IapsRDSCPUUtilWidget,
      local.IapsRDSConnectionsWidget,
      local.IapsRDSMemUtilWidget,
      local.IapsRDSStorageUtilWidget,
      local.IapsRDSReadUtilWidget,
      local.IapsRDSWriteUtilWidget,
      local.IapsRDSNetworkUtilWidget,
      local.IapsRDSCPUCreditUtilWidget,
      local.IapsSystemEventLogWidget,
      local.IapsTotalLogEventsWidget,
    ]
  }

  IapsEC2CPUUtilWidget = {
    type   = "metric"
    x      = 0
    y      = 0
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "EC2 CPU Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["CWAgent", "Processor % Idle Time", "instance", "_Total", "AutoScalingGroupName", module.ec2_iaps_server.autoscaling_group.name, "objectname", "Processor", { color = "#2ca02c", stat = "Minimum" }],
        [".", "Processor % User Time", ".", ".", ".", ".", ".", ".", { color = "#d62728", stat = "Maximum" }]
      ]
    }
  }

  IapsMemUtilWidget = {
    type   = "metric"
    x      = 6
    y      = 6
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "EC2 Memory Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["CWAgent", "Paging File % Usage", "instance", "\\??\\C:\\pagefile.sys", "AutoScalingGroupName", module.ec2_iaps_server.autoscaling_group.name, "objectname", "Paging File", { color = "#d62728" }],
        [".", "Memory % Committed Bytes In Use", "AutoScalingGroupName", module.ec2_iaps_server.autoscaling_group.name, "objectname", "Memory", { label = "Memory % Committed Bytes In Use", color = "#2ca02c" }]
      ]
    }
  }

  IapsEC2DiskUtilWidget = {
    type   = "metric"
    x      = 12
    y      = 0
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "EC2 Disk Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["CWAgent", "PhysicalDisk % Disk Time", "instance", "0 C:", "AutoScalingGroupName", module.ec2_iaps_server.autoscaling_group.name, "objectname", "PhysicalDisk"],
        [".", "LogicalDisk % Free Space", ".", "C:", ".", ".", ".", "LogicalDisk"]
      ]
    }
  }

  IapsErrorLogWidget = {
    type   = "log"
    x      = 0
    y      = 6
    width  = 6
    height = 3
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "Error Log"
      period  = local.cloudwatch_period
      query   = "SOURCE '/iaps/ndinterface/daysummary.log' | fields @timestamp, @message\n| sort @timestamp desc\n| filter @message like /ERROR/\n| stats count() by bin(1m)"
    }
  }

  IapsRDSCPUUtilWidget = {
    type   = "metric"
    x      = 0
    y      = 9
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS CPU Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
        [".", "CPUCreditUsage", ".", "."],
        [".", "BurstBalance", ".", "."]
      ]
    }
  }

  IapsRDSConnectionsWidget = {
    type   = "metric"
    x      = 18
    y      = 9
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Connections"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.iaps.identifier]
      ]
    }
  }

  IapsRDSMemUtilWidget = {
    type   = "metric"
    x      = 12
    y      = 9
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Memory Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
      ]
    }
  }

  IapsRDSStorageUtilWidget = {
    type   = "metric"
    x      = 18
    y      = 15
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Storage Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
      ]
    }
  }

  IapsRDSReadUtilWidget = {
    type   = "metric"
    x      = 0
    y      = 15
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Read Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
        [".", "ReadLatency", ".", "."],
        [".", "ReadThroughput", ".", "."]
      ]
    }
  }

  IapsRDSWriteUtilWidget = {
    type   = "metric"
    x      = 6
    y      = 15
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Write Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
        [".", "WriteLatency", ".", "."],
        [".", "WriteThroughput", ".", "."]
      ]
    }
  }

  IapsRDSNetworkUtilWidget = {
    type   = "metric"
    x      = 12
    y      = 15
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS Network Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "NetworkReceiveThroughput", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
        [".", "NetworkTransmitThroughput", ".", "."]
      ]
    }
  }

  IapsRDSCPUCreditUtilWidget = {
    type   = "metric"
    x      = 6
    y      = 9
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "RDS CPU Credit Utilization"
      period  = local.cloudwatch_period
      metrics = [
        ["AWS/RDS", "CPUCreditUsage", "DBInstanceIdentifier", aws_db_instance.iaps.identifier],
        [".", "CPUCreditBalance", ".", "."]
      ]
    }
  }

  IapsSystemEventLogWidget = {
    type   = "log"
    x      = 18
    y      = 6
    width  = 6
    height = 3
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "System Event Log"
      period  = local.cloudwatch_period
      query   = "SOURCE '/iaps/system-events' | fields @timestamp, @message\n| sort @timestamp desc\n| stats count() by bin(1m)"
    }
  }

  IapsTotalLogEventsWidget = {
    type   = "metric"
    x      = 18
    y      = 0
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = data.aws_region.current.name
      title   = "Total Log Events"
      period  = local.cloudwatch_period
      metrics = [
        for log_group in local.cloudwatch_agent_log_group_names : [
          "AWS/Logs", "IncomingLogEvents", "LogGroupName", "/iaps/${log_group}"
        ]
      ]
    }
  }
}
