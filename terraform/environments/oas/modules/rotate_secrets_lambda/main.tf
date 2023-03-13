#### This file can be used to store secrets specific to the member account ####

locals {
  function_name = "SecretsRotation"
}

resource "aws_lambda_function" "rotate_secrets" {
  filename      = "${path.module}/secret_rotation.zip"
  function_name = local.function_name
  description   = "Secrets Manager password rotation"
  role          = aws_iam_role.lambda.arn
  handler = "index.lambda_handler"
  timeout = var.lambda_timeout
  runtime = var.lambda_runtime

  environment {
    variables = {
      databaseName = var.database_name
      databaseUser = var.database_user
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = merge(
    var.tags,
    { "Name" = "SecretsRotation" },
  )
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/secret_rotation.py"
  output_path = "${path.module}/secret_rotation.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge(
    var.tags,
    { "Name" = "${local.function_name}-ExecutionRole" },
  )
}

resource "aws_iam_policy" "lambda" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name   = "${local.function_name}-Policy"
  tags = merge(
    var.tags,
    { "Name" = "${local.function_name}-Policy" },
  )
  policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
        {
            Effect = "Allow",
            Action = [
                "logs:CreateLogGroup"
            ],
            Resource = ["arn:aws:logs:${var.region}:${var.account_number}:*"]
        },
        {
            Effect = "Allow",
            Action = [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Resource = ["arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/lambda/${local.function_name}:*"]
        },
        {
            Effect = "Allow",
            Action = [
                "secretsmanager:CreateSecret",
                "secretsmanager:ListSecrets",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:PutSecretValue",
                "secretsmanager:UpdateSecretVersionStage",
                "secretsmanager:GetRandomPassword",
                "lambda:InvokeFunction"
            ],
            Resources = "*"
        },
        {
            # Sid = "GenerateARandomStringToExecuteRotation"
            Effect = "Allow",
            Action = [
                "secretsmanager:GetRandomPassword"
            ],
            Resources = "*"
        }
    ]
})

}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_permission" "allow_secret_manager" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secrets.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "rotate_secrets_lambda" {
  name = aws_lambda_function.rotate_secrets.function_name
  retention_in_days = var.log_group_retention_days
  lifecycle {
    prevent_destroy = true
  }
}
