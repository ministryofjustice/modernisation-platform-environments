resource "aws_scheduler_schedule" "schedule" {
  count = var.create_pipeline_schedule ? 1 : 0

  state       = var.enable_pipeline_schedule ? "ENABLED" : "DISABLED"
  name        = var.pipeline_name
  description = var.description
  flexible_time_window {
    mode                      = var.time_window_mode
    maximum_window_in_minutes = var.time_window_mode == "OFF" ? null : var.maximum_window_in_minutes
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = var.state_machine_arn
    role_arn = var.step_function_execution_role_arn

    input = jsonencode({
      StateMachineArn = var.state_machine_arn
      Input           = ""
    })
  }
}