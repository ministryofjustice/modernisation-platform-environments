resource "aws_cloudwatch_log_group" "dummy_log_group" {
  name              = "yjaf-${var.environment}-dummy-log-group"
  retention_in_days = 400
}