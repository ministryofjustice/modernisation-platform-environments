locals {
  s3_bucket         = var.s3_existing_package != null ? try(var.s3_existing_package.bucket, null) : (var.store_on_s3 ? var.s3_bucket : null)
  s3_key            = var.s3_existing_package != null ? try(var.s3_existing_package.key, null) : (var.store_on_s3 ? var.s3_prefix != null ? format("%s%s", var.s3_prefix, replace(local.archive_filename_string, "/^.*//", "")) : replace(local.archive_filename_string, "/^\\.//", "") : null)
  s3_object_version = var.s3_existing_package != null ? try(var.s3_existing_package.version_id, null) : (var.store_on_s3 ? try(aws_s3_object.lambda_package[0].version_id, null) : null)
}

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

resource "aws_lambda_layer_version" "this" {
  count = var.create_layer ? 1 : 0

  layer_name   = var.layer_name
  description  = var.description
  license_info = var.license_info

  compatible_runtimes      = length(var.compatible_runtimes) > 0 ? var.compatible_runtimes : [var.runtime]
  compatible_architectures = var.compatible_architectures
  skip_destroy             = var.layer_skip_destroy

  filename         = "${path.module}/manifests/${var.local_file}"
  source_code_hash = filebase64sha256("${path.module}/manifests/${var.local_file}")

  s3_bucket         = local.s3_bucket
  s3_key            = local.s3_key
  s3_object_version = local.s3_object_version
}
