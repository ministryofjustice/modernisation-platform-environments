#### This file can be used to store secrets specific to the member account ####

# TODO Do we need to add account ids to the lambda policy?
# TODO Turn this into a module with appropriate variables

resource "aws_lambda_function" "rotate_secrets" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/secret_rotation.zip"
  function_name = "SecretsRotation"
  description   = "Secrets Manager password rotation"
  role          = aws_iam_role.lambda.arn
  # role_arn      = aws_iam_role.lambda.arn
  handler = "index.lambda_handler"
  timeout = 300
  runtime = "python3.8"

  environment {
    variables = {
      databaseName = "lambdadb"
      databaseUser = "admin"
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = merge(
    local.tags,
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
  name               = "${aws_lambda_function.rotate_secrets.function_name}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge(
    local.tags,
    { "Name" = "${aws_lambda_function.rotate_secrets.function_name}-ExecutionRole" },
  )
}

resource "aws_iam_policy" "lambda" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name   = "${aws_lambda_function.rotate_secrets.function_name}-Policy"
  tags = merge(
    local.tags,
    { "Name" = "${aws_lambda_function.rotate_secrets.function_name}-Policy" },
  )
  policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
        {
            Effect = "Allow",
            Action = [
                "logs:CreateLogGroup"
            ],
            Resource = ["arn:aws:logs:${local.application_data.accounts[local.environment].region}:*"]
        },
        {
            Effect = "Allow",
            Action = [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Resource = ["arn:aws:logs:${local.application_data.accounts[local.environment].region}:*:log-group:/aws/lambda/${aws_lambda_function.rotate_secrets.function_name}:*"]
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
            Sid = "GenerateARandomStringToExecuteRotation"
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
  retention_in_days = 180
  lifecycle {
    prevent_destroy = true
  }
}
