data "archive_file" "health_signals_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/.build/health_signals.zip"
}

resource "aws_lambda_function" "health_signals" {
  function_name = "${var.name_prefix}-health-signals"
  role          = aws_iam_role.health_signals_lambda.arn

  handler = "handler.lambda_handler"
  runtime = "python3.11"

  timeout     = 60
  memory_size = 256

  filename         = data.archive_file.health_signals_zip.output_path
  source_code_hash = data.archive_file.health_signals_zip.output_base64sha256

  environment {
    variables = {
      HEALTH_NAMESPACE = var.health_namespace
      TENANT_ROLE_NAME = var.tenant_role_name
      TENANTS_JSON     = jsonencode(var.tenants)
      WARN_THRESHOLD   = tostring(var.warn_threshold)
      CRIT_THRESHOLD   = tostring(var.crit_threshold)
      TARGET_REGION    = var.region
      TELEMETRY_LOOKBACK_MINUTES = "15"
      NAT_LOOKBACK_MINUTES       = "15"
      EDGE_LOOKBACK_MINUTES      = "15"
      EDGE_5XX_WARN              = "10"
      EDGE_5XX_CRIT              = "50"
      QUOTA_WARN_RATIO           = "0.01"
      QUOTA_CRIT_RATIO           = "0.90"
    }
  }
}
