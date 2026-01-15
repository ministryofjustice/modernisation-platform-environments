output "dashboard_widgets" {
  description = "local widgets list for debugging purposes"
  value       = local.widgets
}

output "dashboard" {
  description = "aws_cloudwatch_dashboard resource"
  value       = aws_cloudwatch_dashboard.this
}

#output "debug" {
#  description = "debug"
#  value = {
#    widget_groups_search_filter_ec2_ids  = local.widget_groups_search_filter_ec2_ids
#    widget_groups_ec2_keys               = local.widget_groups_ec2_keys
#    widget_groups_ebs_all                = local.widget_groups_ebs_all
#    widget_groups_ebs_iops               = local.widget_groups_ebs_iops
#    widget_groups_ebs_throughput         = local.widget_groups_ebs_throughput
#    widget_groups_ebs_volumes            = local.widget_groups_ebs_volumes
#    widget_groups_ebs_widgets_iops       = local.widget_groups_ebs_widgets_iops
#    widget_groups_ebs_widgets_throughput = local.widget_groups_ebs_widgets_throughput
#    widget_groups_search_filter_ec2      = local.widget_groups_search_filter_ec2
#    widget_group_header_height           = local.widget_group_header_height
#    widget_group_widgets_height          = local.widget_group_widgets_height
#    widget_group_height                  = local.widget_group_height
#    widget_group_y                       = local.widget_group_y
#    widgets_pos                          = local.widgets_pos
#    widgets                              = local.widgets
#  }
#}
