# Cloudwatch Dashboard Module

Why bother?

It can be a pain to manage widget x/y co-ordinates.
If you don't set x,y co-ordinates, the dashboard will look OK
but with some exceptions - the default dashboard won't display
as you might expect on the AWS Console Cloudwatch page.

This module will figure out the co-ordinates for you, and can
easily add a header to each section of widgets.

The idea of this module is you define a set of re-usable
widgets without any x, y, width and height, e.g.:

```
widgets = {
  cpu-utilization-high = {
    type = "metric"
    properties = {
      view    = "timeSeries"
      stacked = false
      region  = "eu-west-2"
      title   = "EC2 cpu-utilization-high"
      stat    = "Maximum"
      metrics = [
        [{ "expression" : "SELECT MAX(CPUUtilization)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
      ]
    }
  }
  instance-status-check-failed = {
    type = "metric"
    properties = {
      view    = "timeSeries"
      stacked = true
      region  = "eu-west-2"
      title   = "EC2 instance-status-check-failed"
      stat    = "Maximum"
      metrics = [
        [{ "expression" : "SELECT MAX(StatusCheckFailed_Instance)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
      ]
    }
  }
}
```

And then define your dashboard as a set of widget groups, e.g.
all EC2 related widgets together. The module will add a header and
the dimensions for you.

```
module "cloudwatch_dashboard" {
  for_each = local.cloudwatch_dashboards

  source = "../../modules/cloudwatch_dashboard"

  dashboard_name = "Cloudwatch-Default"
  periodOverride = "auto"
  start          = "-PT3H"
  widget_groups  = [
    {
      header_markdown = "## EC2"
      width           = 8
      height          = 8
      widgets = [
        local.widgets.cpu-utilization-high,
        local.widgets.instance-status-check-failed,
        null, # pad
        local.widgets.another-ec2-widget-on-next-line
      ]
    },
    {
      header_markdown = "## ALB"
      width           = 24
      height          = 8
      widgets = [
        local.widgets.an-alb-widget,
      ]
    }
  ]
}
```
