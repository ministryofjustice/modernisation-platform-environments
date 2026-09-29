######################################
### Scheduled EC2 SSH Key Rotation Lambda
###
### Rotates the OAS EC2 instance's ec2-user SSH key pair every 90 days
### without requiring the instance to be recreated. See
### lambda/rotate_ssh_key/LAMBDA_README.md for the full design and the
### open questions (cadence/scope/grace-period) this resolves.
######################################

data "archive_file" "rotate_ssh_key_lambda_zip" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/rotate_ssh_key/lambda_function.py"
  output_path = "${path.module}/lambda/rotate_ssh_key/lambda_function.zip"
}

resource "aws_lambda_function" "rotate_ssh_key" {
  count            = contains(["preproduction", "development"], local.environment) ? 1 : 0
  description      = "Rotates the OAS EC2 instance's ec2-user SSH key pair on a schedule."
  function_name    = "oas-rotate-ssh-key-${local.environment}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.rotate_ssh_key_lambda_role[0].arn
  filename         = data.archive_file.rotate_ssh_key_lambda_zip[0].output_path
  source_code_hash = data.archive_file.rotate_ssh_key_lambda_zip[0].output_base64sha256
  timeout          = 120

  environment {
    variables = {
      INSTANCE_ID = aws_instance.oas_app_instance_new[0].id
      SECRET_ID   = aws_secretsmanager_secret.ec2_ssh_private_key[0].id
    }
  }

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-ssh-key" }
  )
}

######################################
### EventBridge Schedule
######################################

resource "aws_cloudwatch_event_rule" "rotate_ssh_key_schedule" {
  count               = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name                = "oas-rotate-ssh-key-schedule-${local.environment}"
  description         = "Triggers OAS EC2 SSH key rotation every 90 days"
  schedule_expression = "rate(90 days)"

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-ssh-key-schedule" }
  )
}

resource "aws_cloudwatch_event_target" "rotate_ssh_key_schedule_target" {
  count     = contains(["preproduction", "development"], local.environment) ? 1 : 0
  rule      = aws_cloudwatch_event_rule.rotate_ssh_key_schedule[0].name
  target_id = "oas-rotate-ssh-key-${local.environment}"
  arn       = aws_lambda_function.rotate_ssh_key[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_rotate_ssh_key" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_ssh_key[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotate_ssh_key_schedule[0].arn
}

######################################
### IAM Resources
######################################

resource "aws_iam_role" "rotate_ssh_key_lambda_role" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-rotate-ssh-key-lambda-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-ssh-key-lambda-role" }
  )
}

resource "aws_iam_policy" "rotate_ssh_key_lambda_policy" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-rotate-ssh-key-lambda-policy-${local.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = [
          aws_instance.oas_app_instance_new[0].arn,
          "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript"
        ]
      },
      {
        # GetCommandInvocation doesn't support resource-level restriction
        Effect   = "Allow"
        Action   = "ssm:GetCommandInvocation"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/oas-rotate-ssh-key-${local.environment}:*"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-ssh-key-lambda-policy" }
  )
}

resource "aws_iam_role_policy_attachment" "rotate_ssh_key_lambda_policy_attach" {
  count      = contains(["preproduction", "development"], local.environment) ? 1 : 0
  role       = aws_iam_role.rotate_ssh_key_lambda_role[0].name
  policy_arn = aws_iam_policy.rotate_ssh_key_lambda_policy[0].arn
}
