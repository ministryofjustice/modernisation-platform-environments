resource "aws_cloudwatch_log_group" "dummy_log_group" {
  name              = "yjaf-${var.environment}-dummy-log-group"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for encrypting CloudWatch Log Group"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}