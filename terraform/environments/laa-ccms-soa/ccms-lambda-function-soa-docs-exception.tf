##########################################################
# IAM Role for CCMS-SOA Quiesced Monitor Lambda
##########################################################
resource "aws_iam_role" "lambda_ccms_soa_quiesced_role" {
  name = "${local.application_name}-${local.environment}-quiesced-role"

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
    Name = "${local.application_name}-${local.environment}-quiesced-role"
  })
}

resource "aws_iam_role_policy" "lambda_ccms_soa_quiesced_policy" {
  name = "${local.application_name}-${local.environment}-quiesced-policy"
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

##########################################################
# Lambda Layer Packaging
#
# NOTES:
# • Layer is built from dependencies defined in:
#     lambda/ccms-soa-edn-quiesced/python/requirements.txt
#
# • Runtime dependencies built for Python 3.13
#
# • Documentation:
#     https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda
#
# • IMPORTANT — Upload the ZIP to S3 BEFORE terraform apply:
#     s3://<app>-<env>-shared/lambda_delivery/<app>-edn-quiesced-layer/layerV1.zip
#
# Otherwise Terraform will error: "S3 Error Code: NoSuchKey"
##########################################################
resource "aws_lambda_layer_version" "lambda_layer_ccms_soa_edn_quiesced" {
  layer_name               = "${local.application_name}-edn-quiesced-layer"
  s3_key                   = "lambda_delivery/${local.application_name}-edn-quiesced-layer/layerV1.zip"
  s3_bucket                = module.s3-bucket-shared.bucket.id
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Layer for CCMS SOA EDN Quiesced notifications"
}

##########################################################
# Lambda ZIP Packaging
##########################################################
data "archive_file" "ccms_soa_quiesced_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ccms-soa-edn-quiesced"
  output_path = "${path.module}/lambda/ccms_soa_quiesced.zip"
}

##########################################################
# Lambda Function - EDN Quiesced Monitor
##########################################################
resource "aws_lambda_function" "ccms_soa_edn_quiesced_monitor" {
  filename         = data.archive_file.ccms_soa_quiesced_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.ccms_soa_quiesced_zip.output_path)
  function_name    = "${local.application_name}-${local.environment}-edn-quiesced-monitor"
  role             = aws_iam_role.lambda_ccms_soa_quiesced_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true
  layers           = [aws_lambda_layer_version.lambda_layer_ccms_soa_edn_quiesced.arn]

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
    Name = "${local.application_name}-${local.environment}-edn-quiesced-monitor"
  })
}

##########################################################
# Allow CloudWatch Logs to Trigger Lambda
##########################################################
resource "aws_lambda_permission" "allow_cloudwatch_invoke_ccms_soa_edn_quiesced" {
  statement_id  = "AllowExecutionFromCloudWatchCCMSSOAQuiesced"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ccms_soa_edn_quiesced_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group_managed.arn}:*"
}
