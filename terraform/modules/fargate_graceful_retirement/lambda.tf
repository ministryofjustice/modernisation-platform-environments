data "archive_file" "lambda_function_ecs_restart_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files"
  output_path = "${path.module}/files/ecs_restart.zip"
  excludes    = ["ecs_restart.zip", "calculate_wait_time.zip", "calculate_wait_time.py"]
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

resource "aws_lambda_function" "ecs_restart_handler" {
  function_name = "ecs_restart_handler"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn

  filename      = data.archive_file.lambda_function_ecs_restart_payload.output_path

  source_code_hash = data.archive_file.lambda_function_ecs_restart_payload.output_base64sha256
}

resource "aws_lambda_permission" "allow_eventbridge_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_restart_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_restart_rule.arn
}


resource "aws_lambda_function" "calculate_wait_time" {
  function_name = "calculate_wait_time"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn

  filename      = data.archive_file.lambda_function_calculate_wait_time_payload.output_path
  source_code_hash = data.archive_file.lambda_function_calculate_wait_time_payload.output_base64sha256
}

data "archive_file" "lambda_function_calculate_wait_time_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files"
  output_path = "${path.module}/files/calculate_wait_time.zip"
  excludes    = ["calculate_wait_time.zip", "lambda.zip", "ecs_restart.py"]
}
