resource "aws_athena_workgroup" "data_product_athena_workgroup" {
  name = "data_product_workgroup"

  configuration {
    enforce_workgroup_configuration    = false
    publish_cloudwatch_metrics_enabled = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://athena-data-product-query-results-${data.aws_caller_identity.current.account_id}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

data "aws_iam_policy_document" "athena_load_lambda_function_policy" {
  statement {
    sid    = "AllowLambdaToCreateLogGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      format("arn:aws:logs:eu-west-2:%s:*", data.aws_caller_identity.current.account_id)
    ]
  }
  statement {
    sid    = "AllowLambdaToWriteLogsToGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      format("arn:aws:logs:eu-west-2:%s:*", data.aws_caller_identity.current.account_id)
    ]
  }
  statement {
    sid    = "s3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-bucket.bucket.arn}/*",
      "${module.s3-bucket.bucket.arn}",
      "${module.s3_athena_query_results_bucket.bucket.arn}",
      "${module.s3_athena_query_results_bucket.bucket.arn}/*"
    ]
  }
  statement {
    sid    = "GluePermissions"
    effect = "Allow"
    actions = [
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:BatchDeleteTableVersion",
      "glue:BatchGetPartition",
      "glue:CreateDatabase",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:CreateTable",
      "glue:DeletePartition",
      "glue:DeletePartitionIndex",
      "glue:DeleteSchema",
      "glue:DeleteTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitionIndexes",
      "glue:GetPartitions",
      "glue:GetSchema",
      "glue:GetSchemaByDefinition",
      "glue:GetSchemaVersion",
      "glue:GetSchemaVersionsDiff",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
      "glue:ListSchemas",
      "glue:UpdatePartition",
      "glue:UpdateRegistry",
      "glue:UpdateSchema",
      "glue:UpdateTable"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "AthenaQueryAccess"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution"
    ]
    resources = [
      aws_athena_workgroup.data_product_athena_workgroup.arn
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "athena_load_lambda_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "athena_load_lambda_role_${local.environment}"
  tags               = local.tags
}

resource "aws_iam_policy" "athena_load_lambda_function_policy" {
  name   = "athena_load_lambda_function_policy"
  policy = data.aws_iam_policy_document.athena_load_lambda_function_policy.json
  tags   = local.tags
}


resource "aws_iam_role_policy_attachment" "policy_from_json" {
  role       = aws_iam_role.athena_load_lambda_role.name
  policy_arn = aws_iam_policy.athena_load_lambda_function_policy.arn
}

resource "aws_lambda_function" "athena_load" {
  function_name                  = "data_product_athena_load_${local.environment}"
  description                    = "Lambda to load and transform raw data products landing in s3. Creates partitioned parquet tables"
  reserved_concurrent_executions = 100
  image_uri                      = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/data-platform-athena-load-lambda-ecr-repo:1.0.0"
  package_type                   = "Image"
  role                           = aws_iam_role.athena_load_lambda_role.arn
  timeout                        = 600
  memory_size                    = 512

  environment {
    variables = {
      ENVIRONMENT = local.environment
    }
  }
}

resource "aws_cloudwatch_event_target" "athena_load_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_data_directory.name
  target_id = "athena"
  arn       = aws_lambda_function.athena_load.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_athena_load_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.athena_load.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_data_directory.arn
}
