# Names resolve in this component's account and region. Missing configured topics
# fail planning, rather than silently discarding alarm notifications.
data "aws_sns_topic" "api_alarms" {
  for_each = toset(compact(values(local.alarm_topic_names)))
  name     = each.value
}

resource "terraform_data" "alarm_configuration" {
  input = local.alarm_topic_names
  lifecycle {
    precondition {
      condition = !contains(["preproduction", "production"], local.environment) || alltrue([
        for priority in ["high_priority", "low_priority"] :
        try(length(trimspace(local.alarm_topic_names[priority])) > 0, false)
      ])
      error_message = "Configure existing platform alarm topic names for both priorities before preproduction/production deployment."
    }
  }
}
