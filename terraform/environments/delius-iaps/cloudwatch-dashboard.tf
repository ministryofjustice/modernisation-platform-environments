resource "aws_cloudwatch_dashboard" "iapsv2" {
  dashboard_name = "iaps"
  dashboard_body = jsonencode(local.dashboard_body)
}

locals {
  dashboard_body = {
    widgets = [
      local.IapsEC2CPUUtilWidget
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
      metrics = [
        [
          [
            "CWAgent",
            "Processor % Idle Time",
            "instance",
            "_Total",
            "AutoScalingGroupName",
            module.ec2_iaps_server.autoscaling_group_name,
            "objectname",
            "Processor",
            {
              color  = "#2ca02c"
              stat   = "Minimum"
              period = 60
            }
          ],
          [
            ".",
            "Processor % User Time",
            ".",
            ".",
            ".",
            ".",
            ".",
            ".",
            {
              color  = "#d62728"
              stat   = "Maximum"
              period = 60
            }
          ]
        ],
      ]
    }
  }
}