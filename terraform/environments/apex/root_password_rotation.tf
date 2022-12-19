variable "secret_rotation_frequency_days" { default = "28" }

variable "lambda_function_name" { default = "system-root-password-rotation" }

variable "lambda_function_description" { default = "Rotate AWS Secrets Manager Secret Value" }

variable "lambda_function_runtime" { default = "python3.8" }

variable "lambda_function_handler" { default = "index.lambda_handler" }

variable "lambda_function_timeout" { default = "300" }

variable "lambda_function_inline_code_filename" {
  description = "Name of file used to provide in-line code to AWS Lambda function"
  default     = "secrets_manager_secret_rotation.py"
}

variable "zip_artefact_filename" {
  description = "Name of temporary zip artefact generated for in-line AWS Lambda function code"
  default     = "inline.zip"
}

# for reasoning behind implementation, refer to:
# https://mojdt.slack.com/archives/C01A7QK5VM1/p1671441837036929

locals {
  lambda_function_name = "${local.application_name}-${var.lambda_function_name}"
}

data "archive_file" "lambda_inline_code" {
  type        = "zip"
  output_path = "./${var.zip_artefact_filename}"

  source {
    filename = var.lambda_function_inline_code_filename
    content  = file(var.lambda_function_inline_code_filename)
  }
}

resource "aws_secretsmanager_secret" "system_root_password" {
  name        = "${local.application_name}/app/db-root-password"
  description = "This secret has a dynamically generated password."

  tags = local.tags
}

resource "aws_secretsmanager_secret_rotation" "system_root_password_rotation" {
  secret_id           = aws_secretsmanager_secret.system_root_password.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret_function.arn

  rotation_rules {
    automatically_after_days = var.secret_rotation_frequency_days
  }
}

resource "aws_lambda_function" "rotate_secret_function" {
  function_name = local.lambda_function_name
  description   = var.lambda_function_description
  role          = aws_iam_role.lambda_function_execution_role.arn
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  timeout       = var.lambda_function_timeout

  filename         = data.archive_file.lambda_inline_code.output_path
  source_code_hash = data.archive_file.lambda_inline_code.output_base64sha256

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = local.tags
}

resource "aws_lambda_permission" "rotate_secret_function_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_iam_role" "lambda_function_execution_role" {
  name = "${local.lambda_function_name}-execution-role"

  assume_role_policy = file("./assume-role-policy.json")

  inline_policy {
    name = "${local.lambda_function_name}-execution-policy"

    policy = templatefile("./lambda-execution-policy.json", {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
      FUNCTION_NAME  = local.lambda_function_name
    })
  }

  tags = local.tags
}
