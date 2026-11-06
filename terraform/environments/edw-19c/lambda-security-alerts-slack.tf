######################################
### Lambda Function
######################################

# Reads the Slack webhook secret and posts credential change events and alarm state changes.
data "archive_file" "security_alerts_slack" {
  count       = local.enable_edw_security_alerts ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/scripts/security-alerts-slack-lambda.zip"

  source {
    content  = file("${path.module}/scripts/security-alerts-slack-lambda.py")
    filename = "lambda_function.py"
  }
}

######################################
### IAM Resources
######################################

resource "aws_iam_role" "security_alerts_slack" {
  count = local.enable_edw_security_alerts ? 1 : 0
  name  = "${local.application_name}-${local.environment}-security-alerts-slack-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-alerts-slack-role" }
  )
}

resource "aws_iam_role_policy_attachment" "security_alerts_slack_basic" {
  count      = local.enable_edw_security_alerts ? 1 : 0
  role       = aws_iam_role.security_alerts_slack[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "security_alerts_slack_secrets" {
  count = local.enable_edw_security_alerts ? 1 : 0
  name  = "${local.application_name}-${local.environment}-security-alerts-slack-secrets"
  role  = aws_iam_role.security_alerts_slack[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.security_alerts_slack_webhook[0].arn
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "security_alerts_slack_lambda" {
  #checkov:skip=CKV_AWS_158: Lambda execution logs, no KMS encryption required
  count             = local.enable_edw_security_alerts ? 1 : 0
  name              = "/aws/lambda/${local.application_name}-${local.environment}-security-alerts-slack"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-alerts-slack-logs" }
  )
}

resource "aws_lambda_function" "security_alerts_slack" {
  count            = local.enable_edw_security_alerts ? 1 : 0
  function_name    = "${local.application_name}-${local.environment}-security-alerts-slack"
  description      = "Posts EDW DB credential change events and security alarms to Slack"
  filename         = data.archive_file.security_alerts_slack[0].output_path
  source_code_hash = data.archive_file.security_alerts_slack[0].output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.security_alerts_slack[0].arn

  environment {
    variables = {
      SLACK_WEBHOOK_SECRET = aws_secretsmanager_secret.security_alerts_slack_webhook[0].name
      ENVIRONMENT          = local.environment
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-alerts-slack" }
  )

  depends_on = [aws_cloudwatch_log_group.security_alerts_slack_lambda]
}

######################################
### Lambda Permissions
######################################

resource "aws_lambda_permission" "allow_db_credential_changes_log_invoke" {
  count         = local.enable_edw_security_alerts ? 1 : 0
  statement_id  = "AllowExecutionFromDbCredentialChangesCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_alerts_slack[0].function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.db_credential_changes[0].arn}:*"
}

resource "aws_lambda_permission" "allow_security_alerts_sns_invoke" {
  count         = local.enable_edw_security_alerts ? 1 : 0
  statement_id  = "AllowExecutionFromSecurityAlertsSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_alerts_slack[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts[0].arn
}

######################################
### CloudWatch Log Subscriptions
######################################

resource "aws_cloudwatch_log_subscription_filter" "db_credential_changes_slack" {
  count           = local.enable_edw_security_alerts ? 1 : 0
  name            = "${local.application_name}-${local.environment}-db-credential-changes-slack"
  log_group_name  = aws_cloudwatch_log_group.db_credential_changes[0].name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.security_alerts_slack[0].arn

  depends_on = [aws_lambda_permission.allow_db_credential_changes_log_invoke]
}
