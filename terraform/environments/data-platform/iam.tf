# IAM policy documents for lambda functions

data "aws_iam_policy_document" "log_to_bucket" {
  statement {
    sid    = "s3LogAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${module.logs_s3_bucket.bucket.arn}",
      "${module.logs_s3_bucket.bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "manage_glue_databases" {
  statement {
    sid    = "gluePermissions"
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
}

data "aws_iam_policy_document" "read_openmetadata_secrets" {
  statement {
    sid       = "openmetdataSecretsManager"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.openmetadata.id]
  }
}
data "aws_iam_policy_document" "read_metadata" {
  statement {
    sid     = "s3ReadMetadata"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "${module.metadata_s3_bucket.bucket.arn}/*",
      "${module.metadata_s3_bucket.bucket.arn}",
    ]
  }
}

data "aws_iam_policy_document" "write_metadata" {
  statement {
    sid       = "s3WriteMetadata"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.metadata_s3_bucket.bucket.arn}/*"]
  }
  statement {
    sid       = "InvokePushToCatalogueLambda"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_push_to_catalogue_lambda.lambda_function_arn]
  }
}

data "aws_iam_policy_document" "create_write_lambda_logs" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

data "aws_iam_policy_document" "athena_load_lambda_function_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
    data.aws_iam_policy_document.manage_glue_databases.json
  ]

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
      "${module.data_s3_bucket.bucket.arn}/raw/*",
      "${module.data_s3_bucket.bucket.arn}/fail/*",
      "${module.data_s3_bucket.bucket.arn}/curated/*",
      "${module.data_s3_bucket.bucket.arn}",
      "${module.s3_athena_query_results_bucket.bucket.arn}",
      "${module.s3_athena_query_results_bucket.bucket.arn}/*"
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

data "aws_iam_policy_document" "landing_to_raw_lambda_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid    = "getDeleteLandingData"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:ListBucket",
    ]
    resources = [
      "${module.data_landing_s3_bucket.bucket.arn}/*",
      "${module.data_landing_s3_bucket.bucket.arn}",
    ]
  }

  statement {
    sid    = "copyToRawFail"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:ListBucket",

    ]
    resources = [
      "${module.data_s3_bucket.bucket.arn}/raw/*",
      "${module.data_s3_bucket.bucket.arn}/raw",
      "${module.data_s3_bucket.bucket.arn}/fail/*",
      "${module.data_s3_bucket.bucket.arn}/fail",
    ]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_authorizer_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]
}

data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid    = "GetPutDataObject"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "${module.data_landing_s3_bucket.bucket.arn}/landing/*",
      "${module.logs_s3_bucket.bucket.arn}/logs/*",
      "${module.data_landing_s3_bucket.bucket.arn}/landing",
      "${module.logs_s3_bucket.bucket.arn}/logs",
    ]
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

data "aws_iam_policy_document" "data_s3_bucket_policy_document" {
  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.data_s3_bucket.bucket.arn}/*"]

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

data "aws_iam_policy_document" "data_landing_s3_bucket_policy_document" {
  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.data_landing_s3_bucket.bucket.arn}/*"]

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

data "aws_iam_policy_document" "metadata_s3_bucket_policy_document" {
  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.metadata_s3_bucket.bucket.arn}/*"]

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

data "aws_iam_policy_document" "logs_s3_bucket_policy_document" {
  statement {
    sid    = "AllowPutFromCloudtrail"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${module.logs_s3_bucket.bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      # If the arn is directly referenced there were issues with circular dependencies
      # So the arn is predicted from it's component parts
      values = ["arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/data_platform_s3_putobject_trail_${local.environment}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [module.logs_s3_bucket.bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      # If the arn is directly referenced there were issues with circular dependencies
      # So the arn is predicted from it's component parts
      values = [aws_cloudtrail.data_s3_put_objects.arn]
    }
  }

  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.logs_s3_bucket.bucket.arn}/*"]

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
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.write_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid     = "ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.metadata_s3_bucket.bucket.arn
    ]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_reload_data_product_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.data_s3_bucket.bucket.arn]
  }
  statement {
    sid       = "InvokeAthenaLoadLambda"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_athena_load_lambda.lambda_function_arn]
  }
  statement {
    sid    = "GlueGetTableDeleteTable"
    effect = "Allow"
    actions = [
      "glue:DeleteTable",
      "glue:GetTables"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_get_schema_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]
}

data "aws_iam_policy_document" "iam_policy_document_for_resync_unprocessed_files_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid     = "ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.data_s3_bucket.bucket.arn
    ]
  }
  statement {
    sid       = "InvokeAthenaLoadLambda"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_athena_load_lambda.lambda_function_arn]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_write_metadata_and_schema" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.write_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]
}

data "aws_iam_policy_document" "iam_policy_document_for_update_schema" {
  source_policy_documents = [
    data.aws_iam_policy_document.write_metadata.json,
    data.aws_iam_policy_document.athena_load_lambda_function_policy.json
  ]
}

resource "aws_iam_role" "api_gateway_cloud_watch_role" {
  name               = "data_platform_apigateway_log_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_policy" {
  statement {
    sid    = "cloudtrailToCloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.data_platform_s3_putobject_trail.name}:log-stream:${local.account_id}_CloudTrail_${local.region}*",
    ]
  }
}

resource "aws_iam_policy" "cloudtrail_cloudwatch_policy" {
  name   = "data_platform_cloudtrail_cloudwatch_policy_${local.environment}"
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_policy.json
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name               = "data_platform_cloudtrail_log_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch" {
  role       = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatchlogs" {
  role       = aws_iam_role.api_gateway_cloud_watch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "aws_iam_policy_document" "iam_policy_document_for_preview_data" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]
  statement {
    sid    = "s3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "${module.data_s3_bucket.bucket.arn}/curated/*",
      "${module.data_s3_bucket.bucket.arn}"
    ]
  }
  statement {
    sid    = "s3AthenaAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3_athena_query_results_bucket.bucket.arn}",
      "${module.s3_athena_query_results_bucket.bucket.arn}/*"
    ]
  }
  statement {
    sid    = "GluePermissions"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:GetPartition",
      "glue:GetDatabases",
      "glue:GetDatabase"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "AthenaQueryAccess"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
    ]
    resources = [
      aws_athena_workgroup.data_product_athena_workgroup.arn
    ]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_delete_table_for_data_product_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.write_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
    data.aws_iam_policy_document.manage_glue_databases.json
  ]

  statement {
    sid    = "s3ListDeleteRawFailCurated"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.data_s3_bucket.bucket.arn}",
      "${module.data_s3_bucket.bucket.arn}/raw/*",
      "${module.data_s3_bucket.bucket.arn}/fail/*",
      "${module.data_s3_bucket.bucket.arn}/curated/*",
      "${module.data_s3_bucket.bucket.arn}/raw",
      "${module.data_s3_bucket.bucket.arn}/fail",
      "${module.data_s3_bucket.bucket.arn}/curated",
    ]
  }

  statement {
    sid    = "s3ListDeleteSchema"
    effect = "Allow"
    actions = [
      "s3:DeleteObject"
    ]
    resources = [
      "${module.metadata_s3_bucket.bucket.arn}/*",
      "${module.metadata_s3_bucket.bucket.arn}"
    ]
  }

  statement {
    sid    = "GlueGetTableDeleteTable"
    effect = "Allow"
    actions = [
      "glue:DeleteTable",
      "glue:GetTable"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_push_to_catalogue_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_openmetadata_secrets.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]
}

data "aws_iam_policy_document" "iam_policy_document_for_delete_data_product_lambda" {
  source_policy_documents = [
    data.aws_iam_policy_document.log_to_bucket.json,
    data.aws_iam_policy_document.read_metadata.json,
    data.aws_iam_policy_document.write_metadata.json,
    data.aws_iam_policy_document.create_write_lambda_logs.json,
  ]

  statement {
    sid    = "s3ListDeleteRawFailCurated"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.data_s3_bucket.bucket.arn}",
      "${module.data_s3_bucket.bucket.arn}/raw/*",
      "${module.data_s3_bucket.bucket.arn}/fail/*",
      "${module.data_s3_bucket.bucket.arn}/curated/*",
      "${module.data_s3_bucket.bucket.arn}/raw",
      "${module.data_s3_bucket.bucket.arn}/fail",
      "${module.data_s3_bucket.bucket.arn}/curated",
    ]
  }

  statement {
    sid    = "s3ListDeleteMetadata"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.metadata_s3_bucket.bucket.arn}/*",
      "${module.metadata_s3_bucket.bucket.arn}"
    ]
  }

  statement {
    sid    = "GlueGetDeleteDatabase"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:DeleteDatabase",
    ]
    resources = [
      "*"
    ]
  }
}
