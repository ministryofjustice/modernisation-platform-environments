resource "aws_cloudwatch_dashboard" "nomis" {
  dashboard_name = "nomis"
  dashboard_body = jsonencode(local.dashboard_body)
}

locals {
  cloudwatch_period = local.environment == "production" ? 300 : 300

  dashboard_body = {
    widgets = [
      local.NomisEC2CPUUtilWidget,
      local.NomisEC2MemoryUtilWidget,
      local.NomisEC2DiskUsed,
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
      region  = data.aws_region.current.name
      title   = "Top 5 instances by highest CPU Utilization"
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
    width  = 8
    height = 6
    properties = {
      view    = "bar"
      stacked = false
      region  = data.aws_region.current.name
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
      region  = data.aws_region.current.name
      title   = "EC2 Memory Utilization %"
      stat    = "Maximum"
      period  = local.cloudwatch_period
      metrics = [
        [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label": "", "id": "q1"} ]
      ]
    }
  }
}

