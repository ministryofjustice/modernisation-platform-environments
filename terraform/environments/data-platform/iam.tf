data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:DescribeImages",
    ]
    resources = ["*"]
  }
}

module "github_actions_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.22.0"

  name = "${local.application_name}-gha"

  policy = data.aws_iam_policy_document.github_actions.json

  tags = local.tags
}

module "github_actions_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.22.0"

  name = "${local.application_name}-gha"

  subjects = ["ministryofjustice/data-platform:*"]

  policies = {
    "github-actions" = module.github_actions_iam_policy.arn
  }

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_trust_policy_doc" {
  statement {
    sid     = "LambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

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

data "aws_iam_policy_document" "iam_policy_document_for_authorizer_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

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
}
