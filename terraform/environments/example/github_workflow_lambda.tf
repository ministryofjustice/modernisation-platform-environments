locals {

    lambda_name                 = "github-workflow-data-poller"
    workflow_log_group_name     = "modernisation-platform-workflow-data"
    workflow_log_retention_days = "90"
    timeout                     = 60
    repo_owner                  = "ministryofjustice"
    repo_name                   = "modernisation-platform"

}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/github_workflow_data_poller"
  output_path = "${path.module}/build/github_workflow_data_poller.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.lambda_name}-role"

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
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.lambda_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Standard Lambda logging permissions for /aws/lambda/* etc.
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # Explicit access to the dedicated workflow-runs log group
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.workflow_runs.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "workflow_runs" {
  name              = local.workflow_log_group_name
  retention_in_days = local.workflow_log_retention_days
}

resource "aws_lambda_function" "github_workflow_runs" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "github_workflow_data_poller.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = local.timeout

  environment {
    variables = {
      GITHUB_OWNER               = local.repo_owner
      GITHUB_REPO                = local.repo_name
      SLOT_MINUTES               = "15"
      WORKFLOW_RUN_LOG_GROUP     = aws_cloudwatch_log_group.workflow_runs.name
    }
  }
}


# EventBridge - Every 15 minutes, 24x7: at :00, :15, :30, :45
resource "aws_cloudwatch_event_rule" "every_15_minutes" {
  name                = "${local.lambda_name}-schedule"
  description         = "Invoke ${local.lambda_name} every 15 minutes"
  schedule_expression = "cron(0/15 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_15_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.github_workflow_runs.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_workflow_runs.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_15_minutes.arn
}