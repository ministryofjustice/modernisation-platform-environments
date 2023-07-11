resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_lambda ? 1 : 0
  name  = "/aws/lambda/${var.name}-function"

  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
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