data "archive_file" "lambda_function_ecs_restart_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/ecs_restart"
  output_path = "${path.module}/files/ecs_restart.zip"
  excludes    = ["ecs_restart.zip", "calculate_wait_time.zip", "ldap_circuit_handler.zip"]
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

data "aws_iam_policy_document" "lambda_ssm_policy_document" {
  statement {
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/ldap/circuit-breaker"]
  }
}

resource "aws_iam_policy" "lambda_ssm_policy" {
  name        = "${var.environment}_lambda_ssm_policy"
  description = "IAM policy for Lambda to interact with SSM"
  policy      = data.aws_iam_policy_document.lambda_ssm_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  policy_arn = aws_iam_policy.lambda_ssm_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

data "aws_iam_policy_document" "lambda_elb_policy_document" {
  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "lambda_elb_policy" {
  name        = "${var.environment}_lambda_elb_policy"
  description = "IAM policy for Lambda to interact with ELB"
  policy      = data.aws_iam_policy_document.lambda_elb_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_elb" {
  policy_arn = aws_iam_policy.lambda_elb_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
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
    resources = ["arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/*"]
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
  description   = "Lambda to restart ECS Tasks"
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

data "archive_file" "lambda_function_calculate_wait_time_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/calculate_wait_time"
  output_path = "${path.module}/files/calculate_wait_time.zip"
  excludes    = ["calculate_wait_time.zip", "ecs_restart.zip", "ldap_circuit_handler.zip"]
}

data "archive_file" "lambda_function_ldap_circuit_handler_payload" {
  type        = "zip"
  source_dir  = "${path.module}/files/ldap_circuit_handler"
  output_path = "${path.module}/files/ldap_circuit_handler.zip"
  excludes    = ["calculate_wait_time.zip", "ecs_restart.zip", "ldap_circuit_handler.zip"]
}

resource "aws_lambda_function" "ldap_circuit_handler" {
  function_name = "${var.environment}_ldap_circuit_handler"
  description   = "Lambda to control LDAP ciruit breaker feature"
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
