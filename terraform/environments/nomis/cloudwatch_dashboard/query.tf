resource "aws_cloudwatch_dashboard" "nomis" {
  dashboard_name = "nomis"
  dashboard_body = jsonencode(local.dashboard_body)
}

locals {

  cloudwatch_period = 300
  region            = "eu-west-2"

  dashboard_body = {
    widgets = [
      local.NomisEC2CPUUtilWidget,
      local.NomisEC2MemoryUtilWidget,
      local.NomisEC2DiskUsed,
      local.NomisLoadBalancerTargetResponseTime,
      local.NomisLoadBalancerRequestCount,
      local.NomisLoadBalancerHTTP5XXsCount,
      local.NomisEBSVolumeDiskIOPS,
      local.NomisEBSVolumeDiskThroughput,
      local.NomisAllEBSVolumeStats,
    ]
  }

  NomisEC2CPUUtilWidget = {
    type   = "metric"
    x      = 0
    y      = 2
    width  = 6
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = local.region
      title   = "Top 5 instances by highest CPU Utilization %"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT MAX(CPUUtilization)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC\nLIMIT 5", "label": "", "id": "q1" } ]
      ]
    }
  }

  NomisEC2MemoryUtilWidget = {
    type   = "metric"
    x      = 6
    y      = 0
    width  = 6
    height = 8
    properties = {
      view    = "bar"
      stacked = false
      region  = local.region
      title   = "EC2 Memory Utilization %"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT MAX(mem_used_percent) FROM SCHEMA(CWAgent, InstanceId,name,server_type) GROUP BY InstanceId ORDER BY MAX() DESC", "label": "", "id": "q1", "yAxis": "left" } ]
      ]
    }
  }

  NomisEC2DiskUsed = {
    type   = "metric"
    x      = 0
    y      = 8
    width  = 6
    height = 7
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = local.region
      title   = "EC2 Disk Used %"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label": "", "id": "q1" } ]
      ]
    }
  }

  NomisLoadBalancerTargetResponseTime = {
    type   = "metric"
    x      = 12
    y      = 0
    width  = 7
    height = 8
    properties = {
      view    = "timeSeries"
      stacked = true
      region  = local.region
      title   = "LoadBalancer Target Response Time"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT MAX(TargetResponseTime) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) GROUP BY TargetGroup ORDER BY MAX() DESC", "label": "", "id": "q1" } ]
      ]
    }
  }

  NomisLoadBalancerRequestCount = {
    type   = "metric"
    x      = 12
    y      = 8
    width  = 7
    height = 8
    properties = {
      view    = "timeSeries"
      stacked = true
      region  = local.region
      title   = "LoadBalancer Request Count"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT COUNT(RequestCount) FROM \"AWS/ApplicationELB\" GROUP BY LoadBalancer ORDER BY COUNT() DESC", "label": "", "id": "q1" } ]
      ]
    }
  }

  NomisLoadBalancerHTTP5XXsCount = {
    type   = "metric"
    x      = 19
    y      = 0
    width  = 5
    height = 7
    properties = {
      view    = "timeSeries"
      stacked = true
      region  = local.region
      title   = "LoadBalancer HTTP 5XXs Count"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT COUNT(HTTPCode_ELB_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", AvailabilityZone,LoadBalancer,TargetGroup) GROUP BY LoadBalancer ORDER BY COUNT() DESC", "label": "", "id": "q1" } ]
      ]
    }
  }

  NomisEBSVolumeDiskIOPS = {
    type   = "metric"
    x      = 0
    y      = 15
    width  = 12
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = local.region
      title   = "EBS Volumes Total IOPs"
      stat    = "Sum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "m1/PERIOD(m1)", "label": "Read IOPs", "id": "e1" } ],
        [ { "expression": "m2/PERIOD(m2)", "label": "Write IOPs", "id": "e2" } ],
        [ { "expression": "e1+e2", "label": "Total IOPs", "id": "e3" } ],
        [ "AWS/EBS", "VolumeReadOps", "VolumeId", "*", { "id": "m1", "visible": false } ],
        [ "AWS/EBS", "VolumeWriteOps", "VolumeId", "*", { "id": "m2", "visible": false } ]
      ]
    }
  }

  NomisEBSVolumeDiskThroughput = {
    type   = "metric"
    x      = 0
    y      = 15
    width  = 12
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = local.region
      title   = "EBS Volumes Total IOPs"
      stat    = "Sum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT SUM(VolumeWriteBytes)\nFROM SCHEMA(\"AWS/EBS\", VolumeId)\nGROUP BY VolumeId\nORDER BY SUM() DESC\nLIMIT 10", "label": "VolumeWriteBytes", "id": "m3", "stat": "Sum", "visible": false } ],
        [ { "expression": "SELECT SUM(VolumeReadBytes) FROM SCHEMA(\"AWS/EBS\", VolumeId) GROUP BY VolumeId ORDER BY SUM() DESC LIMIT 10", "label": "VolumeReadBytes", "id": "m4", "stat": "Sum", "visible": false } ],
        [ { "expression": "(m4/(1024*1024))/PERIOD(m4)", "label": "MB Read Per Second", "id": "e4" } ],
        [ { "expression": "(m3/(1024*1024))/PERIOD(m3)", "label": "MB Write Per Second", "id": "e5" } ],
        [ { "expression": "e4+e5", "label": "Total Consumed MB/s", "id": "e6" } ]
      ]
    }
  }

  NomisAllEBSVolumeStats = {
    type   = "explorer"
    x      = 0
    y      = 21
    width  = 24
    height = 15
    properties = {
      region  = local.region
      title   = "EBS Volumes Total IOPs"
      stat    = "Sum"
      period  = local.cloudwatch_period
      widgetOptions = {
        view          = "timeSeries"
        stacked       = false
        rowsPerPage   = 50
        widgetsPerRow = 2
      }
      labels = [
        { key: "application", value: "nomis" }
      ]
      metrics = [
        { 
          "metricName": "VolumeReadBytes",
          "resourceType": "AWS::EC2::Volume",
          "stat": "Sum"
        },
        {
          "metricName": "VolumeWriteBytes",
          "resourceType": "AWS::EC2::Volume",
          "stat": "Sum"
        },
        {
          "metricName": "VolumeIdleTime",
          "resourceType": "AWS::EC2::Volume",
          "stat": "Average"
        },
        {
          "metricName": "VolumeReadOps",
          "resourceType": "AWS::EC2::Volume",
          "stat": "Sum"
        },
        {
          "metricName": "VolumeWriteOps",
          "resourceType": "AWS::EC2::Volume",
          "stat": "Sum"
        }
      ]
    }
  }
}

