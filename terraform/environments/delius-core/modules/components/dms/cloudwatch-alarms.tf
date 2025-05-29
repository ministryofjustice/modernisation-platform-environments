# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "dms_alerts_topic" {
  name              = "delius-dms-alerts-topic"
  kms_master_key_id = var.account_config.kms_keys.general_shared

  http_success_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
  http_success_feedback_sample_rate = 100
  http_failure_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "dms-checker-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda (permissions to describe DMS tasks and publish to SNS)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "dms-checker-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dms:DescribeReplicationTasks"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ],
        Effect   = "Allow",
        Resource = aws_sns_topic.dms_alerts_topic.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


# Creates a ZIP file which
# contains a Python script to check if any DMS replication task is not running
data "archive_file" "lambda_dms_replication_stopped_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/detect_stopped_replication.py"
  output_path = "${path.module}/lambda/detect_stopped_replication.zip"
}

# Lambda Function to check DMS replication is not running (source in Zip archive)
resource "aws_lambda_function" "dms_checker" {
  function_name = "dms-task-health-checker"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  filename      = "${path.module}/lambda/detect_stopped_replication.zip"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.dms_alerts_topic.arn
    }
  }
}

# EventBridge Rule to Trigger Lambda Every 5 Minutes
resource "aws_cloudwatch_event_rule" "check_dms_every_5_min" {
  name                = "check-dms-every-5-minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.check_dms_every_5_min.name
  target_id = "dms-task-check"
  arn       = aws_lambda_function.dms_checker.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dms_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_dms_every_5_min.arn
}
