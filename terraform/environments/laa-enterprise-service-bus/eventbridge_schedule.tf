resource "aws_scheduler_schedule" "cwa_extract_schedule" {
  name       = "cwa-extract-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 22 ? * WED *)"

  target {
    arn      = aws_lambda_function.cwa_extract_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_role.arn
  }
}