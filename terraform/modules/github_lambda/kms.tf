resource "aws_kms_key" "lambda" {
  description             = "KMS key for Lambda environment variables in ${var.project_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "lambda" {
  name          = "alias/${var.project_name}-lambda-environment"
  target_key_id = aws_kms_key.lambda.key_id
}

resource "aws_kms_key" "scheduler" {
  description             = "KMS key for EventBridge Scheduler payload encryption in ${var.project_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "scheduler" {
  name          = "alias/${var.project_name}-scheduler"
  target_key_id = aws_kms_key.scheduler.key_id
}
