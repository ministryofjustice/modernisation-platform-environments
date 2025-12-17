# CloudWatch -> filter -> event -> Lambda -> SNS Topic -> Slack

resource "aws_iam_role" "lambda_payment_load_monitor_role" {
  name = "${local.application_name}-${local.environment}-payment_load_monitor_role"

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
    Name = "${local.application_name}-${local.environment}-payment-load-monitor"
  })
}

resource "aws_iam_role_policy" "lambda_payment_load_monitor_policy" {
  name = "${local.application_name}-${local.environment}-payment_load_monitor_policy"
  role = aws_iam_role.lambda_payment_load_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda_payment_load_monitor.function_name}:*"

      },
      {
        Action : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Effect   = "Allow",
        Resource = [aws_secretsmanager_secret.ebs_cw_alerts_secrets.arn]
      }
    ]
  })
}

# Lambda Layer -> requirements.txt for layer function has been generated following process in the link but it is same as 
# what has been used for edrms docs exception, also requirements.txt has been added. The zip file for layered function
# have been added in s3 bucket manually. https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda

resource "aws_lambda_layer_version" "payment_load_monitor_layer" {
  layer_name               = "${local.application_name}-${local.environment}-payment-load-monitor-layer"
  s3_key                   = "lambda_delivery/payment_load_monitor_layer/layerV1.zip"
  s3_bucket                = aws_s3_bucket.ccms_ebs_shared.bucket
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} payment load monitor"
}


data "archive_file" "lambda_payment_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/payment_load_monitor"
  output_path = "${path.module}/lambda/payment_load_monitor.zip"
}

resource "aws_lambda_function" "lambda_payment_load_monitor" {
  filename         = data.archive_file.lambda_payment_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_payment_source_hashes))
  function_name    = "${local.application_name}-${local.environment}-payment-load-monitor"
  role             = aws_iam_role.lambda_payment_load_monitor_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.payment_load_monitor_layer.arn]
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

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-payment-load-monitor"
  })
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_payment_load_monitor" {
  name            = "payment-load-filter"
  log_group_name  = "/aws/lambda/${local.application_name}-${local.environment}-payment-load"
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_payment_load_monitor.arn
  # role_arn        = aws_iam_role.lambda_payment_load_monitor_role.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_logs_invoke" {
  statement_id  = "AllowCloudWatchLogsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_payment_load_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.application_name}-${local.environment}-payment-load:*"
}