resource "aws_cloudwatch_log_group" "yjaf_user_journey" {
  name              = "${var.project_name}-${var.environment}/user-journey"
  retention_in_days = 400
}