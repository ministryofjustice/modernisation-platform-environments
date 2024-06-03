locals {

  widget_group_header_height = [
    for widget_group in var.widget_groups : lookup(widget_group, "header_markdown", null) == null ? 0 : 1
  ]
  widget_group_widgets_height = [
    for widget_group in var.widget_groups : widget_group.height * floor((length(widget_group.widgets) + 1) / (24 / widget_group.width))
  ]
  widget_group_height = [
    for i in range(length(var.widget_groups)) : local.widget_group_header_height[i] + local.widget_group_widgets_height[i]
  ]
  widget_group_y = [
    for i in range(length(var.widget_groups)) : i == 0 ? 0 : sum(slice(local.widget_group_height, 0, i))
  ]

  # add header widget and calculate x, y positions
  widgets = flatten([
    for i in range(length(var.widget_groups)) : [
      lookup(var.widget_groups[i], "header_markdown", null) == null ? [] : [{
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = local.widget_group_y[i]
        properties = {
          markdown   = var.widget_groups[i].header_markdown
          background = "solid"
        }
      }],
      [
        for j in range(length(var.widget_groups[i].widgets)) : merge(
          {
            width  = var.widget_groups[i].width
            height = var.widget_groups[i].height
            x      = j * var.widget_groups[i].width % 24
            y      = (floor(j * var.widget_groups[i].width / 24) * var.widget_groups[i].height) + local.widget_group_y[i] + local.widget_group_header_height[i]
          },
          var.widget_groups[i].widgets[j],
          var.accountId == null ? {} : {
            properties = merge(var.widget_groups[i].widgets[j].properties, {
              accountId = var.accountId
            })
          }
        ) if var.widget_groups[i].widgets[j] != null
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
