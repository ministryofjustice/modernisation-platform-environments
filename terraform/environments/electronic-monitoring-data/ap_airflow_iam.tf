data "aws_iam_policy_document" "test_ap_airflow" {
  statement {
    sid       = "TestAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }
}

module "test_ap_airflow" {
  source = "./modules/ap_airflow_iam_role"

  environment         = local.environment
  role_name_suffix    = "test-cross-account-access"
  role_description    = ""
  iam_policy_document = data.aws_iam_policy_document.test_ap_airflow.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn            = aws_iam_openid_connect_provider.analytical_platform_compute.arn
}

module "load_unstructured_atrium_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  name               = "unstructured-atrium-database"
  environment        = local.environment
  database_name      = "g4s-atrium-unstructured"
  path_to_data       = "/g4s/atrium_unstructured"
  source_data_bucket = module.s3-json-directory-structure-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_cap_dw_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  name               = "cap-dw"
  environment        = local.environment
  database_name      = "g4s-cap-dw"
  path_to_data       = "/g4s_cap_dw"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_alcohol_monitoring_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  name               = "alcohol-monitoring"
  environment        = local.environment
  database_name      = "capita-alcohol-monitoring"
  path_to_data       = "/capita_alcohol_monitoring"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}
