locals {

  # add header widget and calculate x, y positions
  # set y to 0 as AWS figures that out OK. 
  widgets = flatten([
    for widget_group in var.widget_groups : [
      lookup(widget_group, "header_markdown", null) == null ? [] : [{
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = 0
        properties = {
          markdown   = widget_group.header_markdown
          background = "solid"
        }
      }],
      [
        for i in range(length(widget_group.widgets)) : merge(widget_group.widgets[i], {
          width  = widget_group.width
          height = widget_group.height
          x      = i * widget_group.width % 24
          y      = 0
        }) if widget_group.widgets[i] != null
      ]
    ]
  ])
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name
  dashboard_body = jsonencode({
    periodOverride = var.periodOverride
    start          = var.start
    widgets        = local.widgets
  })
}
