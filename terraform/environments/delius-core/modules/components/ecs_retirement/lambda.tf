data "archive_file" "lambda_source" {
    type = "zip"
    source_dir = "${path.module}/python/"
    output_path = "${path.module}/assets/ecs_task_retirement.zip"
}

resource "aws_lambda_function" "task_retirement_lambda" {
  function_name = "${var.env_name}-core-task-retirement-slack-alarm"
  description   = "Capture Task Retirement Events"
  handler       = "task_retirement.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10

  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_source.output_path)

  environment {
    variables = {
      ENVIRONMENT   = var.env_name
      SLACK_TOKEN   = "/alfresco/slack/token"
      SLACK_CHANNEL = "probation-migrations-team"
    }
  }

  tags = var.tags
}
