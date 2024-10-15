data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "load_data" {
  statement {
    sid    = "GetFiles${var.name}"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAttributes"
    ]
    resources = ["${var.source_data_bucket.arn}/${var.path_to_data}*"]
  }
  statement {
    sid       = "ListDataBucket${var.name}"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.source_data_bucket.arn]
  }
  statement {
    sid    = "AthenaPermissionsForLoadData${var.name}"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [var.athena_workgroup.arn]
  }
  statement {
    sid    = "GluePermissionsForLoadAtriumUnstructured${var.name}"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${var.database_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.database_name}/*"
    ]
  }
}

module "load_unstructured_atrium_database" {
  source              = "../ap_airflow_iam_role"
  role_name_suffix    = "load-${var.name}"
  role_description    = "${var.name} database permissions"
  iam_policy_document = data.aws_iam_policy_document.load_data.json
  secret_code         = var.secret_code
  oidc_arn            = var.oidc_arn
}
