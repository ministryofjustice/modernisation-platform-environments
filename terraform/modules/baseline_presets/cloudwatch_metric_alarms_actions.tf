# Merge the alarm_actions defined in var.options.cloudwatch_metric_alarms_lists_with_actions 
# with the locals.cloudwatch_metric_alarms_lists
#
# For example:
#
# options.cloudwatch_metric_alarms_lists_with_actions = {
#   standard_alarms = ["sns_topic_name1", "sns_topic_name2"]
#   critical_alarms = ["sns_topic_name3"]
# }
#
# output.cloudwatch_metric_alarms_lists_with_actions = {
#   standard_alarms = {
#     list1 = {
#       alarm1 = {
#         alarm_actions = ["sns_topic_name1", "sns_topic_name2"]
#         ...
#       }
#       ...
#     }
#     ..
#   }
#   critical_alarms = {
#     list1 = {
#       alarm1 = {
#         alarm_actions = ["sns_topic_name3"]
#         ...
#       }
#       ...
#     }
#     ..
#   }

locals {
  cloudwatch_metric_alarms_lists_with_actions = {
    for key, value in var.options.cloudwatch_metric_alarms_lists_with_actions : key => {
      for list_key, list_value in local.cloudwatch_metric_alarms_lists : list_key => {
        for alarm_name, alarm_value in list_value : alarm_name => merge(alarm_value, {
          alarm_actions = value
        })
      }
    }
  }
}
