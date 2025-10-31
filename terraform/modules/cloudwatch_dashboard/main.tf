locals {

  widget_groups_search_filter_ec2_ids = [
    for widget_group in var.widget_groups : distinct(flatten([
      try(widget_group.search_filter.ec2_instance, []),
      [
        for ec2_filter in try(widget_group.search_filter.ec2_tag, []) : [
          for ec2_key, ec2_value in var.ec2_instances :
          ec2_value.aws_instance.id if try(ec2_value.aws_instance.tags_all[ec2_filter.tag_name] == ec2_filter.tag_value, false)
        ]
      ],
    ]))
  ]
  widget_groups_search_filter_ec2 = [
    for i in range(length(var.widget_groups)) : length(local.widget_groups_search_filter_ec2_ids[i]) == 0 ? {} : {
      search_filter = join("", [
        try(var.widget_groups[i].search_filter.negate, false) ? "NOT " : "",
        "InstanceId=(",
        join(" OR ", local.widget_groups_search_filter_ec2_ids[i]),
        ")",
      ])
    }
  ]
  widget_groups_search_filter_dimension = [
    for widget_group in var.widget_groups : lookup(widget_group, "search_filter_dimension", null) == null ? {} : {
      search_filter = join("", [
        lookup(widget_group.search_filter_dimension, "negate", false) ? "NOT " : "",
        widget_group.search_filter_dimension.name,
        "=(",
        join(" OR ", widget_group.search_filter_dimension.values),
        ")",
      ])
    }
  ]

  widget_groups = [
    for i in range(length(var.widget_groups)) : merge(var.widget_groups[i], {
      widgets = concat(
        var.widget_groups[i].widgets,
        local.widget_groups_ebs_widgets_iops[i],
        local.widget_groups_ebs_widgets_throughput[i],
      )
    })
  ]

  widget_group_header_height = [
    for widget_group in local.widget_groups : lookup(widget_group, "header_markdown", null) == null ? 0 : 1
  ]
  widget_group_widgets_height = [
    for widget_group in local.widget_groups : widget_group.height * floor((length(widget_group.widgets) + 1) / (24 / widget_group.width))
  ]
  widget_group_height = [
    for i in range(length(local.widget_groups)) : local.widget_group_header_height[i] + local.widget_group_widgets_height[i]
  ]
  widget_group_y = [
    for i in range(length(local.widget_groups)) : i == 0 ? 0 : sum(slice(local.widget_group_height, 0, i))
  ]

  # add header widget and calculate x, y positions
  widgets_pos = flatten([
    for i in range(length(local.widget_groups)) : [
      lookup(local.widget_groups[i], "header_markdown", null) == null ? [] : [{
        type   = "text"
        width  = 24
        height = 1
        x      = 0
        y      = local.widget_group_y[i]
        properties = {
          markdown   = local.widget_groups[i].header_markdown
          background = "solid"
        }
      }],
      [
        for j in range(length(local.widget_groups[i].widgets)) : merge(
          {
            width  = local.widget_groups[i].width
            height = local.widget_groups[i].height
            x      = j * local.widget_groups[i].width % 24
            y      = (floor(j * local.widget_groups[i].width / 24) * local.widget_groups[i].height) + local.widget_group_y[i] + local.widget_group_header_height[i]
          },
          try(strcontains(local.widget_groups[i].widgets[j].expression, "InstanceId"), false) ? local.widget_groups_search_filter_ec2[i] : {},
          try(strcontains(local.widget_groups[i].widgets[j].expression, local.widget_groups[i].search_filter_dimension.name), false) ? local.widget_groups_search_filter_dimension[i] : {},
          local.widget_groups[i].widgets[j],
          var.accountId == null && lookup(local.widget_groups[i], "accountId", null) == null ? {} : {
            properties = merge(local.widget_groups[i].widgets[j].properties, {
              accountId = coalesce(lookup(local.widget_groups[i], "accountId", null), var.accountId)
            })
          }
        ) if local.widget_groups[i].widgets[j] != null
      ]
    ]
  ])

  widgets = [
    for widget in local.widgets_pos : {
      type   = widget.type
      width  = widget.width
      height = widget.height
      x      = widget.x
      y      = widget.y
      properties = merge(
        widget.properties,
        lookup(widget, "expression", null) == null ? {} : {
          metrics = concat(
            [[merge(
              {
                expression = lookup(widget, "search_filter", null) == null ? widget.expression : replace(widget.expression, "MetricName=", "${widget.search_filter} MetricName=")
                label      = ""
                id         = "q1"
                visible    = lookup(widget, "expression_math", null) == null ? true : false
              },
              lookup(widget, "expression_period", null) == null ? {} : {
                period = widget.expression_period
              }
            )]],
            lookup(widget, "expression_math", null) == null ? [] : [[merge(
              {
                expression = widget.expression_math
                label      = ""
                id         = "m1"
              },
              lookup(widget, "expression_period", null) == null ? {} : {
                period = widget.expression_period
              }
            )]]
          )
        },
        lookup(widget, "alarm_threshold", null) == null ? {} : {
          # Annotation currently failing with 'Should match exactly one schema in oneOf' error
          #annotations = {
          #  horizontal = [
          #    {
          #      label = "Alarm Threshold"
          #      value = widget.alarm_threshold
          #      fill  = lookup(widget, "alarm_fill", "above")
          #    }
          #  ]
          #}
        }
      )
    }
  ]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name
  dashboard_body = jsonencode({
    periodOverride = var.periodOverride
    start          = var.start
    widgets        = local.widgets
  })
}
