resource "aws_iam_role" "lambda_cloudwatch_sns_role" {
  name = "${local.application_name}-${local.environment}-lambda_cloudwatch_sns_role"

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
    Name = "${local.application_name}-${local.environment}-lambda_cloudwatch_sns_role"
  })
}

resource "aws_iam_role_policy" "lambda_cloudwatch_sns_policy" {
  name = "${local.application_name}-${local.environment}-lambda_cloudwatch_sns_role_policy"
  role = aws_iam_role.lambda_cloudwatch_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [aws_secretsmanager_secret.ebs_cw_alerts_secrets.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.cloudwatch_sns.function_name}:*"
      }
    ]
  })
}

# resource "aws_sns_topic" "certificate_expiration_alerts" {
#   name = "${local.application_name}-${local.environment}-acm-certificate-alerts"
#   tags = merge(local.tags, {
#     Name = "${local.application_name}-${local.environment}-certificate-monitor"
#   })
# }

resource "aws_sns_topic_subscription" "lambda_cloudwatch_sns" {
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_sns.arn
}

# Lambda Layer
resource "aws_lambda_layer_version" "lambda_cloudwatch_sns_layer" {
  # filename                 = "lambda/layerV1.zip"
  layer_name               = "${local.application_name}-${local.environment}-cloudwatch-sns-layer"
  s3_key                   = "lambda_delivery/cloudwatch_sns_layer/layerV1.zip"
  s3_bucket                = aws_s3_bucket.ccms_ebs_shared.bucket
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} CloudWatch SNS Alarm Integration"
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir= "${path.module}/lambda/cloudwatch_alarm_slack_integration"
  output_path = "${path.module}/lambda/cloudwatch_alarm_slack_integration.zip"
}

resource "aws_lambda_function" "cloudwatch_sns" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${local.application_name}-${local.environment}-cloudwatch-alarm-slack-integration"
  role             = aws_iam_role.lambda_cloudwatch_sns_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_cloudwatch_sns_layer.arn]
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.ebs_cw_alerts_secrets.name
    }
  }

  tracing_config {
    mode = "Active"
  }
  
  lifecycle {
    ignore
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-cloudwatch-alarm-slack-integration"
  })
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cw_alerts.arn
}
