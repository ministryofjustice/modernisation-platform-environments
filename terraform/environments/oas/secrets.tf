#### This file can be used to store secrets specific to the member account ####

resource "aws_lambda_function" "secrets" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename        = "terraform/environments/oas/secret_rotation.py"
  function_name   = local.application_data.accounts[local.environment].lambda_function_name
  role            = aws_iam_role.iam_for_lambda.arn
  # role_arn      = aws_iam_role.lambda.arn
  handler         = local.application_data.accounts[local.environment].lambda_handler
  timeout         = 30
  runtime         = local.application_data.accounts[local.environment].lambda_runtime
  # source_code_hash = data.archive_file.lambda.output_base64sha256

  # module_tags = {
  #   Environment = "development"
  # }
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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

