locals {
  camel-sid      = join("", [for word in split("-", var.name) : title(word)])
  snake-database = replace(var.database_name, "-", "_")
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "load_data" {
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_111
  statement {
    sid    = "GetFiles${local.camel-sid}"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAttributes"
    ]
    resources = [
      "${var.source_data_bucket.arn}${var.path_to_data}/*",
      "${var.source_data_bucket.arn}/staging${var.path_to_data}/*",
      "${var.cadt_bucket.arn}/staging${var.path_to_data}/*",
      "${var.athena_dump_bucket.arn}/output/*"
    ]
  }
  statement {
    sid     = "ListDataBucket${local.camel-sid}"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      var.source_data_bucket.arn,
      var.athena_dump_bucket.arn,
      var.cadt_bucket.arn
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadData${local.camel-sid}"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GluePermissionsForLoadAtriumUnstructured${local.camel-sid}"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.snake-database}*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.snake-database}*/*"
    ]
  }
  statement {
    sid       = "ListAccountAlias${local.camel-sid}"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucket${local.camel-sid}"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

module "load_unstructured_atrium_database" {
  source = "../ap_airflow_iam_role"

  environment         = var.environment
  role_name_suffix    = "load-${var.name}"
  role_description    = "${var.name} database permissions"
  iam_policy_document = data.aws_iam_policy_document.load_data.json
  secret_code         = var.secret_code
  oidc_arn            = var.oidc_arn
}
