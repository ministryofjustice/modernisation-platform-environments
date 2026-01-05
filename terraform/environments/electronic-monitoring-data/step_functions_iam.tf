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
  count = local.is-development || local.is-production ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      module.dms_retrieve_metadata[0].lambda_function_arn,
    module.dms_validation[0].lambda_function_arn]
  }
}

resource "aws_iam_policy" "dms_validation_step_function_policy" {
  count = local.is-development || local.is-production ? 1 : 0

  name   = "dms_validation_step_function_role"
  policy = data.aws_iam_policy_document.dms_validation_step_function_policy_document[0].json
}


# ------------------------------------------
# Data Cut Back
# ------------------------------------------

data "aws_iam_policy_document" "data_cutback_policy_document" {
  count = local.is-development || local.is-production ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = module.data_cutback[0].lambda_function_arn
  }
}

resource "aws_iam_policy" "data_cutback_step_function_policy" {
  count = local.is-development || local.is-production ? 1 : 0

  name   = "dms_validation_step_function_role"
  policy = data.aws_iam_policy_document.data_cutback_policy_document[0].json
}
