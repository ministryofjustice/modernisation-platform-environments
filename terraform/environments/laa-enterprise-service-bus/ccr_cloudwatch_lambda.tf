######################################
### Lambda Resources
######################################
resource "aws_lambda_function" "cloudwatch_log_alert" {
  function_name = "cloudwatch_log_alert"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.ccr_cloudwatch_log_alert_role.arn
  filename      = "lambda/cloudwatch_log_alert/cloudwatch_log_alert.zip"
  timeout       = 60

  environment {
    variables = {
      ALERT_TOPIC_ARN = aws_sns_topic.hub2_alerts.arn
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cloudwatch-log-alert" }
  )
}



######################################
### IAM Resources
######################################
resource "aws_iam_role" "ccr_cloudwatch_log_alert_role" {
  name = "${local.application_name_short}-ccr-cloudwatch-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccr-cloudwatch-lambda-role"
    }
  )
}

resource "aws_iam_policy" "ccr_cloudwatch_log_alert_policy" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.hub2_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ccr_cloudwatch_log_alert_attach" {
  role       = aws_iam_role.ccr_cloudwatch_log_alert_role.name
  policy_arn = aws_iam_policy.ccr_cloudwatch_log_alert_policy.arn
}

resource "aws_iam_role_policy_attachment" "ccr_cloudwatch_log_alert_vpc_access" {
  role       = aws_iam_role.ccr_cloudwatch_log_alert_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


######################################
### CloudWatch Resources
######################################
resource "aws_cloudwatch_log_subscription_filter" "lambda_error_alert" {
  name            = "lambda-error-alert"
  log_group_name  = "/aws/lambda/cwa_extract_lambda"
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}