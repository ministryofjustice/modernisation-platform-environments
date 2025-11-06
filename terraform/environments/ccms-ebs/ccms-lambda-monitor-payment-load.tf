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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.payment_load_notifications.arn]
      }
    ]
  })
}

resource "aws_sns_topic" "payment_load_notifications" {
  name = "${local.application_name}-${local.environment}-payment-load-notifications"
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-payment-load-notifications"
  })
}

resource "aws_sns_topic_subscription" "payment_load_notofications_email" {
  topic_arn = aws_sns_topic.payment_load_notifications.arn
  protocol  = "email"
  endpoint  = local.application_data.accounts[local.environment].payment_load_monitor_email
}

resource "aws_lambda_function" "lambda_payment_load_monitor" {
  # filename         = "./lambda/payment_load_monitor.zip"
  s3_bucket        = local.application_data.accounts[local.environment].lambda_s3_bucket
  s3_key           = "lambda_delivery/payment_load_monitor/payment_load_monitor.zip"
  source_code_hash = filebase64sha256("./lambda/payment_load_monitor.zip")
  function_name    = "${local.application_name}-${local.environment}-payment-load-monitor"
  role             = aws_iam_role.lambda_payment_load_monitor_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.payment_load_notifications.arn
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

output "sns_topic_arn_payment_load_monitor" {
  description = "ARN of the SNS topic for Payment Load monitor"
  value       = aws_sns_topic.payment_load_notifications.arn
}

output "lambda_function_arn_lambda_payment_load_monitor" {
  description = "ARN of the Payment Load monitor Lambda function"
  value       = aws_lambda_function.lambda_payment_load_monitor.arn
}
