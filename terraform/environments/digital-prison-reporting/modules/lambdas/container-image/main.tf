resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"

  count = var.enable_lambda ? 1 : 0
  name  = "/aws/lambda/${var.name}-function"

  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_272: "TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  count = var.enable_lambda ? 1 : 0

  function_name                  = "${var.name}-function"
  role                           = aws_iam_role.lambda_execution_role[0].arn
  package_type                   = "Image"
  image_uri                      = var.image_uri
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

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

  ephemeral_storage {
    size = var.ephemeral_storage_size
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
