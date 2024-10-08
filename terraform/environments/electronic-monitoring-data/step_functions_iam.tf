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

# --------------------------------
# Send database to AP
# -------------------------------- 

data "aws_iam_policy_document" "send_database_to_ap" {
  statement {
    effect = "Allow"

    actions = [
      "athena:startQueryExecution",
      "athena:getQueryExecution",
      "athena:getQueryResults"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      module.s3-athena-bucket.bucket.arn,
      "${module.s3-athena-bucket.bucket.arn}/*",
      "${module.s3-dms-data-validation-bucket.bucket.arn}/*",
      module.s3-dms-data-validation-bucket.bucket.arn
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:GetTables"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${module.send_table_to_ap.lambda_function_arn}:*",
      "${module.get_file_keys_for_table.lambda_function_arn}:*",
      "${module.query_output_to_list.lambda_function_arn}:*",
      "${module.update_log_table.lambda_function_arn}:*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      module.send_table_to_ap.lambda_function_arn,
      module.get_file_keys_for_table.lambda_function_arn,
      module.query_output_to_list.lambda_function_arn,
      module.update_log_table.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "send_database_to_ap" {
  name        = "send_database_to_ap_athena_queries"
  description = "Policy to allow start and get specific Athena queries"
  policy      = data.aws_iam_policy_document.send_database_to_ap_athena_queries.json
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
