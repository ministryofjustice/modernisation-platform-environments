resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.enable_lambda ? 1 : 0
  name  = "/aws/lambda/${var.name}-function"

  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_272: "TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"

  count         = var.enable_lambda ? 1 : 0
  function_name = "${var.name}-function"

  filename    = var.filename
  s3_bucket   = var.s3_bucket
  s3_key      = var.s3_key
  role        = aws_iam_role.this[0].arn
  runtime     = var.runtime
  handler     = var.handler
  memory_size = var.memory_size
  publish     = var.publish
  timeout     = var.timeout
  layers      = var.layers

  tracing_config {
    mode = var.tracing
  }

  dynamic "vpc_config" {
    for_each = var.vpc_settings != null ? [true] : []
    content {
      subnet_ids         = lookup(var.vpc_settings, "subnet_ids", null)
      security_group_ids = lookup(var.vpc_settings, "security_group_ids", null)
    }
  }

  environment {
    variables = var.env_vars
  }

  tags = var.tags
}

resource "aws_lambda_permission" "this" {
  count         = var.enable_lambda && var.lambda_trigger ? 1 : 0
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.trigger_bucket_arn
}