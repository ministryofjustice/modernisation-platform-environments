data "archive_file" "lambda_function_ecs_restart_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/ecs_restart"
  output_path = "${path.module}/files/ecs_restart.zip"
  excludes    = ["ecs_restart.zip", "calculate_wait_time.zip"]
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_ecs" {
  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:ListServices"
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*"]
  }
}

resource "aws_iam_policy" "lambda_ecs" {
  name        = "${var.environment}_lambda_ecs_policy"
  description = "IAM policy for Lambda to interact with ECS"
  policy      = data.aws_iam_policy_document.lambda_ecs.json
}

resource "aws_iam_role_policy_attachment" "lambda_ecs" {
  policy_arn = aws_iam_policy.lambda_ecs.arn
  role       = aws_iam_role.lambda_execution_role.name
}


resource "aws_lambda_function" "ecs_restart_handler" {
  function_name = "${var.environment}_ecs_restart_handler"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = merge(
      {
        DEBUG_LOGGING = var.debug_logging
        ENVIRONMENT   = var.environment
      },
      var.extra_environment_vars
    )
  }

  filename         = data.archive_file.lambda_function_ecs_restart_payload.output_path
  source_code_hash = data.archive_file.lambda_function_ecs_restart_payload.output_base64sha256
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "${var.environment}-AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_restart_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_restart_rule.arn
}


resource "aws_lambda_function" "calculate_wait_time" {
  function_name = "${var.environment}_calculate_wait_time"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = merge(
      {
        DEBUG_LOGGING = var.debug_logging
        ENVIRONMENT   = var.environment
      },
      var.extra_environment_vars
    )
  }

  filename         = data.archive_file.lambda_function_calculate_wait_time_payload.output_path
  source_code_hash = data.archive_file.lambda_function_calculate_wait_time_payload.output_base64sha256
}

data "archive_file" "lambda_function_ldap_circuit_handler_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/calculate_wait_time"
  output_path = "${path.module}/files/calculate_wait_time.zip"
  excludes    = ["calculate_wait_time.zip", "ecs_restart.zip"]
}

data "archive_file" "lambda_function_calculate_wait_time_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/ldap_circuit_handler"
  output_path = "${path.module}/files/ldap_circuit_handler.zip"
  excludes    = ["calculate_wait_time.zip", "ecs_restart.zip", "ldap_circuit_handler.zip"]
}

resource "aws_lambda_function" "ldap_circuit_handler" {
  function_name = "${var.environment}_ldap_circuit_handler"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = merge(
      {
        DEBUG_LOGGING = var.debug_logging
        ENVIRONMENT   = var.environment
      },
      var.extra_environment_vars
    )
  }

  filename         = data.archive_file.lambda_function_ldap_circuit_handler_payload.output_path
  source_code_hash = data.archive_file.lambda_function_ldap_circuit_handler_payload.output_base64sha256
}
