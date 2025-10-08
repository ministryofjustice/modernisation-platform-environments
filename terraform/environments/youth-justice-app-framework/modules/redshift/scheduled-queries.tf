resource "aws_lambda_function" "redshift_scheduler" {
  function_name = "redshift_scheduler"
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
      SQL_QUERY_2_FILE   = "/var/task/scripts/qs2-fte_redshift.sql"
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
  name = "lambda-redshift-scheduler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult"
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



# Daily materialized views refresh at 5am UTC
resource "aws_cloudwatch_event_rule" "daily_mvs_refresh" {
  name                = "daily-mvs-refresh-${var.environment}"
  schedule_expression = "cron(0 5 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_mvs_refresh_lambda" {
  rule = aws_cloudwatch_event_rule.daily_mvs_refresh.name
  arn  = aws_lambda_function.redshift_scheduler.arn

  input = jsonencode({
    query = "materialized_views"
  })
}


# Weekly FTE refresh on Mondays at 08:30 UTC
resource "aws_cloudwatch_event_rule" "weekly_fte_refresh" {
  name                = "weekly-fte-refresh-${var.environment}"
  schedule_expression = "cron(30 8 ? * 2 *)"  # Monday 08:30 UTC
}

resource "aws_cloudwatch_event_target" "weekly_fte_refresh_lambda" {
  rule = aws_cloudwatch_event_rule.weekly_fte_refresh.name
  arn  = aws_lambda_function.redshift_scheduler.arn

  input = jsonencode({
    query = "fte_redshift"
  })
}


# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_daily" {
  statement_id  = "AllowEventBridgeDaily"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_mvs_refresh.arn
}

resource "aws_lambda_permission" "allow_eventbridge_weekly" {
  statement_id  = "AllowEventBridgeWeekly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_fte_refresh.arn
}
