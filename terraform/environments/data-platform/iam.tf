# IAM policy documents for lambda functions

data "aws_iam_policy_document" "iam_policy_document_for_docs_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
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

data "aws_iam_policy_document" "iam_policy_document_for_authorizer_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_get_glue_metadata_lambda" {
  statement {
    sid     = "GlueReadOnly"
    effect  = "Allow"
    actions = ["glue:GetTable", "glue:GetTables", "glue:GetDatabase", "glue:GetDatabases"]
    resources = [
      "arn:aws:glue:${local.region}:${local.account_id}:catalog",
      "arn:aws:glue:${local.region}:${local.account_id}:database/*",
      "arn:aws:glue:${local.region}:${local.account_id}:table/*"
    ]
  }
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  statement {
    sid       = "GetPutDataObject"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/raw_data/*"]
  }
  statement {
    sid       = "ListExistingDataProducts"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3-bucket.bucket.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["code/*"]
    }
  }
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

# API Gateway authoriser IAM permissions

data "aws_iam_policy_document" "apigateway_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "authoriser_role" {
  name               = "authoriser_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "allow_invoke_authoriser_lambda_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_authorizer_lambda.lambda_function_arn]
  }
}

resource "aws_iam_policy" "allow_invoke_authoriser_lambda" {
  name   = "allow_invoke_authoriser_lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_invoke_authoriser_lambda_doc.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_allow_invoke_authoriser_lambda" {
  role       = aws_iam_role.authoriser_role.name
  policy_arn = aws_iam_policy.allow_invoke_authoriser_lambda.arn
}

# S3 policy

data "aws_iam_policy_document" "data_platform_product_bucket_policy_document" {
  statement {
    sid    = "AllowPutFromCiUser"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }

    actions = ["s3:PutObject", "s3:ListBucket"]

    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }

  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

}

# api gateway create data product metdata permissions
data "aws_iam_policy_document" "iam_policy_document_for_create_metadata_lambda" {
  statement {
    sid     = "GetPutDataObject"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      "${module.s3-bucket.bucket.arn}/metadata/*",
      "${module.s3-bucket.bucket.arn}/data_product_metadata_spec/*"
    ]
  }

  statement {
    sid     = "PutDataObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3-bucket.bucket.arn}/logs/*"
    ]
  }

  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }

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
}

data "aws_iam_policy_document" "iam_policy_document_for_reload_data_product_lambda" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }
  statement {
    sid       = "InvokeAthenaLoadLambda"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_authorizer_lambda.lambda_function_arn]
  }
  statement {
    sid    = "GlueGetDeleteTable"
    effect = "Allow"
    actions = [
      "glue:DeleteTable",
      "glue:GetTables"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid     = "PutLogDataObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3-bucket.bucket.arn}/logs/*"
    ]
  }
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_resync_unprocessed_files_lambda" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }
  statement {
    sid       = "InvokeAthenaLoadLambda"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_authorizer_lambda.lambda_function_arn]
  }
  statement {
    sid     = "PutLogDataObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3-bucket.bucket.arn}/logs/*"
    ]
  }
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}
