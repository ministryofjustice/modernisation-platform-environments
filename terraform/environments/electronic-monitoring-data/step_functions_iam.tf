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

# ------------------------------------------
# DMS Validation
# ------------------------------------------

data "aws_iam_policy_document" "dms_validation_step_function_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.dms_validation.lambda_function_arn]
  }
}

resource "aws_iam_policy" "dms_validation_step_function_policy" {
  name   = "dms_validation_step_function_role"
  policy = data.aws_iam_policy_document.dms_validation_step_function_policy_document.json
}
