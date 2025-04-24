data "aws_iam_policy_document" "genesys_ap_airflow" {
  statement {
    sid    = "GenesysAPAirflowPermissionsListBuckets"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]
    resources = [
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn}/*",
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn}/*",
      module.s3_bucket_staging.bucket.arn,
      "${module.s3_bucket_staging.bucket.arn}/*",
    ]
  }
}

module "genesys_ap_airflow" {
  source = "./modules/ap_airflow_iam_role"

  environment         = local.environment
  role_name_suffix    = "genesys-ap-cross-account-access"
  role_description    = ""
  iam_policy_document = data.aws_iam_policy_document.genesys_ap_airflow.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn            = aws_iam_openid_connect_provider.analytical_platform_compute.arn
}

data "aws_iam_policy_document" "p1_export_airflow" {
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_111
  statement {
    sid    = "AthenaPermissionsForP1Export"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:ListQueryExecutions",
      "athena:GetWorkGroup",
      "athena:ListWorkGroups"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "S3AthenaQueryBucketPermissionsForP1Export"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:CopyObject"
    ]
    resources = [
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn}/bronze/*",
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn}/silver/*",
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn}/*"
    ]
  }
  statement {
    sid    = "GluePermissionsForP1Export"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "S3ExportBucketPermissionsForP1Export"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:CopyObject"
    ]
    resources = [
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn}/*",
      module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn,
      "${module.s3_bucket_landing_archive_ingestion_curated["call-centre-archive-"].bucket.arn}/*",
    ]
  }
  statement {
    sid       = "GetDataAccessForLakeFormationForP1Export"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAliasForP1Export"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid    = "ListAllBuckesForP1Export"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "s3:CopyObject"
    ]
    resources = ["*"]
  }
}

module "load_genesys_laa_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  # data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  # de_role_arn             = try(one(data.aws_iam_roles.data_engineering_roles.arns))

  name               = "genesys_laa"
  environment        = local.environment
  database_name      = "genesys-laa"
  path_to_data       = "/genesys_laa"
  source_data_bucket = module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket
  cadt_bucket        = module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket
}
