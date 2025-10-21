data "archive_file" "lambda_source" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/assets/ecs_task_retirement.zip"
}

resource "aws_lambda_function" "task_retirement_lambda" {
  #checkov:skip=CKV_AWS_50 "ignore"
  #checkov:skip=CKV_AWS_117 "ignore"
  #checkov:skip=CKV_AWS_116 "ignore"
  #checkov:skip=CKV_AWS_115 "ignore"
  #checkov:skip=CKV_AWS_173 "ignore"
  #checkov:skip=CKV_AWS_272 "ignore"
  function_name = "${var.env_name}-core-task-retirement-slack-alarm"
  description   = "Capture Task Retirement Events"
  handler       = "task_retirement.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10

  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_source.output_path)

  environment {
    variables = {
      ENVIRONMENT   = var.env_name
      SLACK_TOKEN   = "/deliusawsalerts/slack-token"
      SLACK_CHANNEL = "probation-migrations-team"
    }
  }

  tags = var.tags
}
