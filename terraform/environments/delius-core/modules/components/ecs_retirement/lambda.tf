data "archive_file" "lambda_source" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/assets/ecs_task_retirement.zip"
}

resource "aws_lambda_function" "task_retirement_lambda" {
  #checkov:skip=CKV_AWS_50 "X-Ray tracing not required"
  #checkov:skip=CKV_AWS_117: "VPC not required - Lambda only calls AWS APIs via service endpoints"
  #checkov:skip=CKV_AWS_116: "DLQ not required"
  #checkov:skip=CKV_AWS_173: "Env Vars are not sensitive"
  #checkov:skip=CKV_AWS_272: "Doesn't require code signing"
  function_name = "${var.env_name}-core-task-retirement-slack-alarm"
  description   = "Capture Task Retirement Events"
  handler       = "task_retirement.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10

  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_source.output_path)

  reserved_concurrent_executions = 10

  environment {
    variables = {
      ENVIRONMENT   = var.env_name
      SLACK_TOKEN   = "/deliusawsalerts/slack-token"
      SLACK_CHANNEL = "probation-migrations-team"
    }
  }

  tags = var.tags
}
