locals {

  cloudwatch_dashboard_widgets = {

    EC2GraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 0
      width  = 24
      height = 1
      properties = {
        markdown   = "## EC2 Graphed Metrics"
        background = "solid"
      }
    }

    EC2CPUUtil = {
      type   = "metric"
      x      = 0
      y      = 1
      width  = 7
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "Top instances by highest CPU Utilization %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(CPUUtilization)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC\nLIMIT 20", "label" : "", "id" : "q1" }]
        ]
        annotations = {
          horizontal = [
            {
              visible = true
              color   = "#9467bd"
              label   = "Alarm threshold"
              value   = 95
              fill    = "above"
              yAxis   = "right"
            }
          ]
        }
      }
    }

    EC2MemoryUtil = {
      type   = "metric"
      x      = 7
      y      = 1
      width  = 6
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EC2 Memory Utilization %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(mem_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }]
        ]
      }
    }

    EC2DiskUsed = {
      type   = "metric"
      x      = 13
      y      = 1
      width  = 6
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EC2 Disk Used %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EC2CPUIOWait = {
      type   = "metric"
      x      = 13
      y      = 1
      width  = 6
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = false
        region  = "eu-west-2"
        title   = "EC2 Disk Used %"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(cpu_usage_iowait) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerTargetResponseTime = {
      type   = "metric"
      x      = 0
      y      = 10
      width  = 7
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = true
        region  = "eu-west-2"
        title   = "LoadBalancer Target Response Time"
        stat    = "Maximum"
        metrics = [
          [{ "expression" : "SELECT MAX(TargetResponseTime) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) GROUP BY TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerRequestCount = {
      type   = "metric"
      x      = 7
      y      = 10
      width  = 6
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = true
        region  = "eu-west-2"
        title   = "LoadBalancer Request Count"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT COUNT(RequestCount) FROM \"AWS/ApplicationELB\" GROUP BY LoadBalancer ORDER BY COUNT() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    LoadBalancerHTTP5XXsCount = {
      type   = "metric"
      x      = 13
      y      = 10
      width  = 6
      height = 8
      properties = {
        view    = "timeSeries"
        stacked = true
        region  = "eu-west-2"
        title   = "LoadBalancer HTTP 5XXs Count"
        stat    = "Sum"
        metrics = [
          [{ "expression" : "SELECT COUNT(HTTPCode_ELB_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", AvailabilityZone,LoadBalancer,TargetGroup) GROUP BY LoadBalancer ORDER BY COUNT() DESC", "label" : "", "id" : "q1" }]
        ]
      }
    }

    EBSVolumeDiskIOPS = {
      type   = "metric"
      x      = 0
      y      = 19
      width  = 12
      height = 6
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
          ["AWS/EBS", "VolumeReadOps", "VolumeId", "*", { "id" : "m1", "visible" : false }],
          ["AWS/EBS", "VolumeWriteOps", "VolumeId", "*", { "id" : "m2", "visible" : false }]
        ]
      }
    }

    EBSVolumeDiskThroughput = {
      type   = "metric"
      x      = 0
      y      = 25
      width  = 12
      height = 6
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

    AllEBSVolumeStats = {
      type   = "explorer"
      x      = 0
      y      = 31
      width  = 24
      height = 15
      properties = {
        region = "eu-west-2"
        title  = "All EBS Volume Stats"
        stat   = "Sum"
        widgetOptions = {
          view          = "timeSeries"
          stacked       = false
          rowsPerPage   = 50
          widgetsPerRow = 2
        }
        labels = [
          { key : "application", value : "${var.environment.application_name}" }
        ]
        metrics = [
          {
            "metricName" : "VolumeReadBytes",
            "resourceType" : "AWS::EC2::Volume",
            "stat" : "Sum"
          },
          {
            "metricName" : "VolumeWriteBytes",
            "resourceType" : "AWS::EC2::Volume",
            "stat" : "Sum"
          },
          {
            "metricName" : "VolumeIdleTime",
            "resourceType" : "AWS::EC2::Volume",
            "stat" : "Average"
          },
          {
            "metricName" : "VolumeReadOps",
            "resourceType" : "AWS::EC2::Volume",
            "stat" : "Sum"
          },
          {
            "metricName" : "VolumeWriteOps",
            "resourceType" : "AWS::EC2::Volume",
            "stat" : "Sum"
          }
        ]
      }
    }

    LBGraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 9
      width  = 24
      height = 1
      properties = {
        markdown   = "## LoadBalancer Graphed Metrics"
        background = "solid"
      }
    }

    EBSGraphedMetricsHeading = {
      type   = "text"
      x      = 0
      y      = 18
      width  = 24
      height = 1
      properties = {
        markdown   = "## EBS Volume Graphed Metrics"
        background = "solid"
      }
    }

  }

  cloudwatch_dashboards = {
    "CloudWatch-Default" = {
      periodOverride = "auto"
      start          = "-PT3H"
      widgets = [
        local.cloudwatch_dashboard_widgets.EC2CPUUtil,
        local.cloudwatch_dashboard_widgets.EC2MemoryUtil,
        local.cloudwatch_dashboard_widgets.EC2DiskUsed,
        local.cloudwatch_dashboard_widgets.LoadBalancerTargetResponseTime,
        local.cloudwatch_dashboard_widgets.LoadBalancerRequestCount,
        local.cloudwatch_dashboard_widgets.LoadBalancerHTTP5XXsCount,
        local.cloudwatch_dashboard_widgets.EBSVolumeDiskIOPS,
        local.cloudwatch_dashboard_widgets.EBSVolumeDiskThroughput,
        local.cloudwatch_dashboard_widgets.AllEBSVolumeStats,
        local.cloudwatch_dashboard_widgets.LBGraphedMetricsHeading,
        local.cloudwatch_dashboard_widgets.EC2GraphedMetricsHeading,
        local.cloudwatch_dashboard_widgets.EBSGraphedMetricsHeading,
      ]
    }
  }
}
