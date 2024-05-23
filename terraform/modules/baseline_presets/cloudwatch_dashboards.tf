locals {

  cloudwatch_dashboard_widgets = {

    LoadBalancerGraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 0
      width  = 24
      height = 1
      properties = {
        markdown   = "## LoadBalancer Graphed Metrics"
        background = "solid"
      }
    }

    LoadBalancerRequestCount = {
      type   = "metric"
      x      = 0
      y      = 1
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Sum LoadBalancer Requests"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT SUM(RequestCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY SUM() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerHTTP4XXsCount = {
      type   = "metric"
      x      = 8
      y      = 1
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Sum LoadBalancer HTTP 4XXs"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT SUM(HTTPCode_ELB_4XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerHTTP5XXsCount = {
      type   = "metric"
      x      = 16
      y      = 1
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Sum LoadBalancer HTTP 5XXs"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT SUM(HTTPCode_ELB_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerUnhealthyTargets = {
      type   = "metric"
      x      = 0
      y      = 9
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max LoadBalancer Unhealthy Targets"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerAverageTargetResponseTime = {
      type   = "metric"
      x      = 8
      y      = 9
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Average LoadBalancer Target Response Time"
        stat    = "Average"
        metrics = [
          [{ "expression" : "SELECT AVG(TargetResponseTime) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerMaximumTargetResponseTime = {
      type   = "metric"
      x      = 16
      y      = 9
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max LoadBalancer Target Response Time"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(TargetResponseTime) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    ACMCertificateDaysToExpiry = {
      type   = "metric"
      x      = 0
      y      = 17
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Min ACM Certificate Days To Expiry"
        stat    = "Minimum"
        metrics = [
          [{ "expression" : "SELECT MIN(DaysToExpiry) FROM SCHEMA(\"AWS/CertificateManager\", CertificateArn) GROUP BY CertificateArn ORDER BY MIN() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2GraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 25
      width  = 24
      height = 1
      properties = {
        markdown   = "## EC2 Graphed Metrics"
        background = "solid"
      }
    }

    EC2CPUUtilization = {
      type   = "metric"
      x      = 0
      y      = 26
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max EC2 CPU Utilization %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(CPUUtilization)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2InstanceStatus = {
      type   = "metric"
      x      = 8
      y      = 26
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EC2 Instance Status"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(StatusCheckFailed_Instance)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2SystemStatus = {
      type   = "metric"
      x      = 16
      y      = 26
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EC2 System Status"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(StatusCheckFailed_Instance)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC\nLIMIT 20", "label" : "", "id" : "q1" }],
          [{ "expression" : "SELECT MAX(StatusCheckFailed_System)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC\nLIMIT 20", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2WindowsMemoryUtilization = {
      type   = "metric"
      x      = 0
      y      = 34
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max EC2 Windows Memory Utilization %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(Memory % Committed Bytes In Use) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }]
        ]
      }
    }

    EC2WindowsDiskFree = {
      type   = "metric"
      x      = 8
      y      = 34
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Min EC2 Windows Disk Free %"
        stat    = "Minimum"
        metrics = [
          [{ "expression" : "SELECT MIN(DISK_FREE) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MIN() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }]
        ]
      }
    }

    EC2LinuxMemoryUtilization = {
      type   = "metric"
      x      = 0
      y      = 42
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max EC2 Linux Memory Utilization %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(mem_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }]
        ]
      }
    }

    EC2LinuxDiskUsed = {
      type   = "metric"
      x      = 8
      y      = 42
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max EC2 Linux Disk Used %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2LinuxCPUIOWait = {
      type   = "metric"
      x      = 16
      y      = 42
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Max EC2 Linux CPU Usage IOWait %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(cpu_usage_iowait) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EBSGraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 43
      width  = 24
      height = 1
      properties = {
        markdown   = "## EBS Volume Graphed Metrics"
        background = "solid"
      }
    }

    EBSVolumeDiskIOPS = {
      type   = "metric"
      x      = 0
      y      = 44
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EBS Volumes Total IOPs"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "m1/PERIOD(m1)", "label" : "Read IOPs", "id" : "e1" }],
          [{ "expression" : "m2/PERIOD(m2)", "label" : "Write IOPs", "id" : "e2" }],
          [{ "expression" : "e1+e2", "label" : "Total IOPs", "id" : "e3" }],
          ["AWS/EBS", "VolumeReadOps", "*", { "id" : "m1", "visible" : false }],
          ["AWS/EBS", "VolumeWriteOps", "*", { "id" : "m2", "visible" : false }]
        ]
      }
    }

    EBSVolumeDiskThroughput = {
      type   = "metric"
      x      = 8
      y      = 44
      width  = 8
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EBS Volumes Throughput"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT SUM(VolumeWriteBytes)\nFROM SCHEMA(\"AWS/EBS\", VolumeId)\nGROUP BY VolumeId\nORDER BY SUM() DESC\nLIMIT 10", "label" : "VolumeWriteBytes", "id" : "m3", "stat" : "Sum", "visible" : false }],
          [{ "expression" : "SELECT SUM(VolumeReadBytes) FROM SCHEMA(\"AWS/EBS\", VolumeId) GROUP BY VolumeId ORDER BY SUM() DESC LIMIT 10", "label" : "VolumeReadBytes", "id" : "m4", "stat" : "Sum", "visible" : false }],
          [{ "expression" : "(m4/(1024*1024))/PERIOD(m4)", "label" : "MB Read Per Second", "id" : "e4" }],
          [{ "expression" : "(m3/(1024*1024))/PERIOD(m3)", "label" : "MB Write Per Second", "id" : "e5" }],
          [{ "expression" : "e4+e5", "label" : "Total Consumed MB/s", "id" : "e6" }]
        ]
      }
    }
  }


  cloudwatch_dashboards = {
    "CloudWatch-Default" = {
      periodOverride = "auto"
      start          = "-PT3H"
      widgets = [
        local.cloudwatch_dashboard_widgets.LoadBalancerGraphedMetricsHeading,
        local.cloudwatch_dashboard_widgets.LoadBalancerRequestCount,
        local.cloudwatch_dashboard_widgets.LoadBalancerHTTP4XXsCount,
        local.cloudwatch_dashboard_widgets.LoadBalancerHTTP5XXsCount,
        local.cloudwatch_dashboard_widgets.LoadBalancerUnhealthyTargets,
        local.cloudwatch_dashboard_widgets.LoadBalancerAverageTargetResponseTime,
        local.cloudwatch_dashboard_widgets.LoadBalancerMaximumTargetResponseTime,
        local.cloudwatch_dashboard_widgets.ACMCertificateDaysToExpiry,
        local.cloudwatch_dashboard_widgets.EC2GraphedMetricsHeading,
        local.cloudwatch_dashboard_widgets.EC2CPUUtilization,
        local.cloudwatch_dashboard_widgets.EC2InstanceStatus,
        local.cloudwatch_dashboard_widgets.EC2SystemStatus,

        local.cloudwatch_dashboard_widgets.EC2WindowsMemoryUtilization,
        local.cloudwatch_dashboard_widgets.EC2WindowsDiskFree,
        local.cloudwatch_dashboard_widgets.EC2LinuxMemoryUtilization,
        local.cloudwatch_dashboard_widgets.EC2LinuxDiskUsed,
        local.cloudwatch_dashboard_widgets.EC2LinuxCPUIOWait,
        local.cloudwatch_dashboard_widgets.EBSGraphedMetricsHeading,
        local.cloudwatch_dashboard_widgets.EBSVolumeDiskIOPS,
        local.cloudwatch_dashboard_widgets.EBSVolumeDiskThroughput,
      ]
    }
  }
}
