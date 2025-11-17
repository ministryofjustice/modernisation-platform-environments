resource "aws_iam_role" "lambda_edrms_docs_exception_role" {
  name = "${local.application_name}-${local.environment}-edrms_docs_exception_role"

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
    Name = "${local.application_name}-${local.environment}-edrms-docs-exception-role"
  })
}

resource "aws_iam_role_policy" "lambda_edrms_docs_exception_policy" {
  name = "${local.application_name}-${local.environment}-edrms-docs-exception_policy"
  role = aws_iam_role.lambda_edrms_docs_exception_role.id

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
        Resource = [aws_sns_topic.cloudwatch_slack.arn]
      }
    ]
  })
}

resource "aws_lambda_function" "edrms_docs_exception_monitor" {
  filename         = "./lambda/edrms_docs_exception.zip"
  source_code_hash = filebase64sha256("./lambda/edrms_docs_exception.zip")
  function_name    = "${local.application_name}-${local.environment}-edrms-docs-exception-monitor"
  role             = aws_iam_role.lambda_edrms_docs_exception_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      LOG_GROUP_NAME      = aws_cloudwatch_log_group.log_group_edrms.name
      SNS_TOPIC_ARN       = aws_sns_topic.cloudwatch_slack.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-edrms-docs-exception-monitor"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.edrms_docs_exception_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group_edrms.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "edrms_docs_exception_filter" {
  name            = "${local.application_name}-${local.environment}-edrms-docs-exception-filter"
  log_group_name  = aws_cloudwatch_log_group.log_group_edrms.name
  filter_pattern  = "\"EdrmsDocumentException\""
  destination_arn = aws_lambda_function.edrms_docs_exception_monitor.arn

  depends_on = [ aws_lambda_permission.allow_cloudwatch_invoke ]
}