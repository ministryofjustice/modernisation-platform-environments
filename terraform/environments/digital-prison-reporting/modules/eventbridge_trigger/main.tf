resource "aws_scheduler_schedule" "schedule" {
  count = var.create_eventbridge_schedule ? 1 : 0

  state       = var.enable_eventbridge_schedule ? "ENABLED" : "DISABLED"
  name        = var.eventbridge_trigger_name
  description = var.description
  flexible_time_window {
    mode                      = var.time_window_mode
    maximum_window_in_minutes = var.time_window_mode == "OFF" ? null : var.maximum_window_in_minutes
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = var.arn
    role_arn = var.role_arn
    input    = var.input
  }
}