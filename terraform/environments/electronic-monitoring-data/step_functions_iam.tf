# ------------------------------------------
# Fake Athena Layer
# ------------------------------------------

data "aws_iam_policy_document" "lambda_invoke_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${module.get_metadata_from_rds_lambda.lambda_function_arn}:*",
      "${module.create_athena_table.lambda_function_arn}:*",
      "${module.get_file_keys_for_table.lambda_function_arn}:*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      module.get_metadata_from_rds_lambda.lambda_function_arn,
      module.create_athena_table.lambda_function_arn,
      module.get_file_keys_for_table.lambda_function_arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "LambdaInvokePolicy"
  description = "Policy to allow invoking specific Lambda functions"
  policy      = data.aws_iam_policy_document.lambda_invoke_policy.json
}

# ------------------------------------------
# Unzip Files
# ------------------------------------------

data "aws_iam_policy_document" "trigger_unzip_lambda" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      module.unzip_single_file.lambda_function_arn,
      module.unzipped_presigned_url.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "trigger_unzip_lambda" {
  name   = "trigger_unzip_lambda"
  policy = data.aws_iam_policy_document.trigger_unzip_lambda.json
}
