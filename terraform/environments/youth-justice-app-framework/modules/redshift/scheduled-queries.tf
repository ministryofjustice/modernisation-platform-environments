resource "aws_lambda_function" "redshift_scheduler" {
  function_name = "redshift_scheduler_${var.environment}"
  runtime       = "python3.11"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_redshift.arn
  timeout       = 30
  memory_size   = 128
  filename = "${path.module}/lambda/redshift_scheduler.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/redshift_scheduler.zip")

  environment {
    variables = {
      REDSHIFT_WORKGROUP = aws_redshiftserverless_workgroup.default.workgroup_name
      SECRET_ARN         = aws_secretsmanager_secret.yjb_schedular.arn
      SQL_QUERY_1        = "CALL yjb_ianda_team.refresh_materialized_views();"
      SQL_QUERY_2_FILE   = "/var/task/scripts/fte_redshift.sql"
      DATABASE_NAME      = "yjb_returns"
    }
  }
}


# IAM Role for Lambda
resource "aws_iam_role" "lambda_redshift" {
  name = "lambda-redshift-executor-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_redshift_policy" {
  role = aws_iam_role.lambda_redshift.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "redshift-serverless:GetCredentials",
          "redshift-serverless:ExecuteStatement",
          "redshift-serverless:BatchExecuteStatement",
          "redshift-serverless:DescribeStatement",
          "redshift-serverless:CancelStatement"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.yjb_schedular.arn
      },
      {
        Sid      = "AllowKMSDecryptForSecret",
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = var.kms_key_arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}



# EventBridge Rule - Daily at 5am
resource "aws_cloudwatch_event_rule" "daily_5am" {
  name                = "daily-redshift-refresh-mvs-${var.environment}"
  schedule_expression = "cron(0 5 * * ? *)"  # UTC time
}

resource "aws_cloudwatch_event_target" "daily_5am_target" {
  rule = aws_cloudwatch_event_rule.daily_5am.name
  arn  = aws_lambda_function.redshift_scheduler.arn
}


# EventBridge Rule - Weekly Monday at 08:30
resource "aws_cloudwatch_event_rule" "weekly_monday" {
  name                = "weekly-fte-redshift-${var.environment}"
  schedule_expression = "cron(30 8 ? * MON *)"  # UTC time
}

resource "aws_cloudwatch_event_target" "weekly_monday_target" {
  rule = aws_cloudwatch_event_rule.weekly_monday.name
  arn  = aws_lambda_function.redshift_scheduler.arn
}


resource "aws_lambda_permission" "allow_eventbridge_daily" {
  statement_id  = "AllowExecutionFromEventBridgeDaily"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_5am.arn
}

resource "aws_lambda_permission" "allow_eventbridge_weekly" {
  statement_id  = "AllowExecutionFromEventBridgeWeekly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_monday.arn
}
