resource "aws_scheduler_schedule" "cwa_extract_schedule" {
  count      = local.environment == "development" ? 1 : 0
  name       = "cwa-extract-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 22 ? * WED *)"

  target {
    arn      = aws_sfn_state_machine.sfn_state_machine.arn
    role_arn = aws_iam_role.scheduler_invoke_role.arn
  }
}