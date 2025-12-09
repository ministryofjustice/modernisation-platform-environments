# IAM Role for CCMS-SOA Quiesced Monitor Lambda
resource "aws_iam_role" "lambda_ccms_soa_quiesced_role" {
  name = "${local.application_name}-${local.environment}-ccms-soa-quiesced-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-ccms-soa-quiesced-role"
  })
}

resource "aws_iam_role_policy" "lambda_ccms_soa_quiesced_policy" {
  name = "${local.application_name}-${local.environment}-ccms-soa-quiesced-policy"
  role = aws_iam_role.lambda_ccms_soa_quiesced_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.ccms_soa_edn_quiesced_monitor.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.log_group_managed.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [aws_secretsmanager_secret.ccms_soa_quiesced_secrets.arn]
      }
    ]
  })
}

# Lambda Layer
resource "aws_lambda_layer_version" "lambda_layer_ccms_soa_edn_quiesced" {
  layer_name               = "${local.application_name}-${local.environment}-ccms-soa-edn-quiesced-layer"
  s3_key                   = "lambda_delivery/${local.application_name}-ccms-soa-edn-quiesced-layer/layerV1.zip"
  s3_bucket                = module.s3-bucket-shared.bucket.id
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Layer for CCMS SOA EDN Quiesced notifications"
}

# Lambda Function
resource "aws_lambda_function" "ccms_soa_edn_quiesced_monitor" {
  filename         = data.archive_file.ccms_soa_quiesced_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_source_hashes))
  function_name    = "${local.application_name}-${local.environment}-ccms-soa-edn-quiesced-monitor"
  role             = aws_iam_role.lambda_ccms_soa_quiesced_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_layer_ccms_soa_edn_quiesced.arn]
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.log_group_managed.name
      SECRET_NAME    = aws_secretsmanager_secret.ccms_soa_quiesced_secrets.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-ccms-soa-edn-quiesced-monitor"
  })
}

# Permission for CloudWatch Logs to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_invoke_ccms_soa_quiesced" {
  statement_id  = "AllowExecutionFromCloudWatchCCMSSOAQuiesced"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ccms_soa_edn_quiesced_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group_managed.arn}:*"
}

data "archive_file" "ccms_soa_quiesced_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ccms-soa-edn-quiesced"
  output_path = "${path.module}/lambda/ccms_soa_quiesced.zip"
}
