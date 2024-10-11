data "aws_iam_policy_document" "test_ap_airflow" {
  statement {
    sid       = "TestAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }
}

module "test_ap_airflow" {
  source              = "./modules/ap_airflow_iam_role"
  role_name_suffix    = "test-cross-account-access"
  role_description    = ""
  iam_policy_document = data.aws_iam_policy_document.test_ap_airflow.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn            = aws_iam_openid_connect_provider.analytical_platform_compute.arn
}


data "aws_iam_policy_document" "load_unstructured_atrium_database" {
  statement {
    sid    = "GetAtriumFiles"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAttributes"
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/g4s/atrium_unstructured/*"]
  }
  statement {
    sid       = "ListDataBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3-data-bucket.bucket.arn]
  }
  statement {
    sid    = "AthenaPermissionsForLoadAtriumUnstructured"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [aws_athena_workgroup.default.arn]
  }
  statement {
    sid    = "GluePermissionsForLoadAtriumUnstructured"
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
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/g4s_atrium_unstructured",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/g4s_atrium_unstructured/*"
    ]
  }
}

module "load_unstructured_atrium_database" {
  count               = local.is-production ? 1 : 0
  source              = "./modules/ap_airflow_iam_role"
  role_name_suffix    = "load-unstructured-atrium-database"
  role_description    = "Atrium database permissions"
  iam_policy_document = data.aws_iam_policy_document.load_unstructured_atrium_database.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn            = aws_iam_openid_connect_provider.analytical_platform_compute.arn
}
