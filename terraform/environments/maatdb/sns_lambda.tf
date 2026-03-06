resource "aws_iam_role" "lambda_dbmaintenance_sns_role" {
  name = "${local.application_name}-${local.environment}-lambda_dbmaintenance_sns_role"

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
    Name = "${local.application_name}-${local.environment}-lambda_dbmaintenance_sns_role"
  })
}

# Inline policy for the Lambda execution role (dbmaintenance) - aligned to existing style
resource "aws_iam_role_policy" "lambda_dbmaintenance_sns_policy" {
  name = "${local.application_name}-${local.environment}-lambda-dbmaintenance-sns-policy"
  role = aws_iam_role.lambda_dbmaintenance_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- Secrets Manager: read Slack webhook secret (and allow version enumeration like your other role) ---
      {
        Sid    = "AllowReadSlackSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [
          aws_secretsmanager_secret.maatdb_maintenance_slack_secrets.arn
        ]
      },

      # --- CloudWatch Logs (scoped to this Lambda's log group, like your existing role) ---
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.dbmaintenance_sns_to_slack.function_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_dbmaintenance_sns_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/rds_maintenance_notify.py"
  output_path = "${path.module}/lambda/rds_maintenance_notify.zip"
}

resource "aws_lambda_function" "dbmaintenance_sns_to_slack" {
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${local.application_name}-${local.environment}-rds_maintenance_notify"
  role             = aws_iam_role.lambda_dbmaintenance_sns_role.arn
  handler          = "rds_maintenance_notify.lambda_handler"
  #  layers           = [aws_lambda_layer_version.lambda_dbmaintenance_sns_layer.arn]
  runtime = "python3.13"
  timeout = 30
  publish = true

  environment {
    variables = {
      # This secret now contains slack_channel_webhook_crimeapps ,slack_channel_webhook_maatdb_dbas
      SECRET_NAME = aws_secretsmanager_secret.maatdb_maintenance_slack_secrets.name
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-rds-maintenance-notify"
  })
}

resource "aws_lambda_permission" "allow_rds_sns_invoke" {
  statement_id  = "AllowExecutionFromrdsSNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dbmaintenance_sns_to_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.maatdb_maintenance_topic.arn
}