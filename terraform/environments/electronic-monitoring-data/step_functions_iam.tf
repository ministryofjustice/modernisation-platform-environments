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

# ------------------------------------------
# Regenerate JSONL data
# ------------------------------------------

data "aws_iam_policy_document" "regenerate_jsonl_policies" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${module.output_file_structure_as_json_from_zip.lambda_function_arn}:*",
      module.output_file_structure_as_json_from_zip.lambda_function_arn,
    ]
  }
  statement {
    sid    = "S3PermissionsForFindingTargetZips"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectV2",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*",
      module.s3-data-bucket.bucket.arn
    ]
  }
}

resource "aws_iam_policy" "regenerate_jsonl_policy" {
  name        = "RegenerateJsonlPolicy"
  description = "Policy to allow invoking a specific lambda on specific resources"
  policy      = data.aws_iam_policy_document.regenerate_jsonl_policies.json
}