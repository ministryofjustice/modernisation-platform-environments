resource "aws_scheduler_schedule" "example" {
  name       = "my-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 hour)"

  target {
    arn      = aws_sqs_queue.example.arn
    role_arn = aws_iam_role.example.arn
  }
}