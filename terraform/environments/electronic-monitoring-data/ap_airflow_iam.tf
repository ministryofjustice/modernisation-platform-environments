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

  environment          = local.environment
  role_name_suffix     = "test-cross-account-access"
  role_description     = ""
  iam_policy_documents = [data.aws_iam_policy_document.test_ap_airflow.json]
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
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
      "s3:ListBucket"
    ]
    resources = [
      module.s3-athena-bucket.bucket.arn,
      "${module.s3-athena-bucket.bucket.arn}/output/airflow_export_em_data_p1/*",
    ]
  }
  statement {
    sid    = "S3DataBucketListPutMetadataGetRequests"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
      "${module.s3-data-bucket.bucket.arn}/p1/*"
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
      "s3:GetObject"
    ]
    resources = [
      module.s3-p1-export-bucket.bucket_arn,
      "${module.s3-p1-export-bucket.bucket_arn}/*",
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
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
}

module "p1_export_airflow" {
  source = "./modules/ap_airflow_iam_role"

  environment          = local.environment
  role_name_suffix     = "export-em-data-p1"
  role_description     = "Permissions to generate P1 export data"
  iam_policy_documents = [data.aws_iam_policy_document.p1_export_airflow.json]
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  new_airflow          = true
}

resource "aws_lakeformation_permissions" "p1_s3_access" {
  count       = local.is-development ? 0 : 1
  principal   = module.p1_export_airflow.iam_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "p1_database_access" {
  count       = local.is-development ? 0 : 1
  principal   = module.p1_export_airflow.iam_role.arn
  permissions = ["DESCRIBE"]
  database {
    name = "allied_mdss${local.db_suffix}"
  }
}

resource "aws_lakeformation_permissions" "p1_table_access" {
  count       = local.is-development ? 0 : 1
  principal   = module.p1_export_airflow.iam_role.arn
  permissions = ["SELECT"]
  table {
    database_name = "allied_mdss${local.db_suffix}"
    wildcard      = true
  }
}

module "load_alcohol_monitoring_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "alcohol-monitoring"
  environment        = local.environment
  database_name      = "capita-alcohol-monitoring"
  path_to_data       = "/capita_alcohol_monitoring"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
}

module "load_orca_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "orca"
  environment        = local.environment
  database_name      = "civica-orca"
  path_to_data       = "/civica_orca"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_atrium_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "atrium"
  environment        = local.environment
  database_name      = "g4s-atrium"
  path_to_data       = "/g4s_atrium"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
}

module "load_atv_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "atv"
  environment        = local.environment
  database_name      = "g4s-atv"
  path_to_data       = "/g4s_atv"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_cap_dw_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "cap-dw"
  environment          = local.environment
  database_name        = "g4s-cap-dw"
  path_to_data         = "/g4s_cap_dw"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60
}

module "load_emsys_mvp_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "emsys-mvp"
  environment          = local.environment
  database_name        = "g4s-emsys-mvp"
  path_to_data         = "/g4s_emsys_mvp"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60
  new_airflow          = true
}

module "load_emsys_tpims_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "emsys-tpims"
  environment          = local.environment
  database_name        = "g4s-emsys-tpims"
  path_to_data         = "/g4s_emsys_tpims"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60

  new_airflow = true
}


module "load_lcm_archive_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "lcm-archive"
  environment          = local.environment
  database_name        = "g4s-lcm-archive"
  path_to_data         = "/g4s_lcm_archive"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60

  new_airflow = true
}

module "load_centurion_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "centurion"
  environment          = local.environment
  database_name        = "g4s-centurion"
  path_to_data         = "/g4s_centurion"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60

  new_airflow = true
}

module "load_fep_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "fep"
  environment        = local.environment
  database_name      = "g4s-fep"
  path_to_data       = "/g4s_fep"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_rf_hours_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "rf-hours"
  environment        = local.environment
  database_name      = "g4s-rf-hours"
  path_to_data       = "/g4s_rf_hours"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_subject_history_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "subject-history"
  environment        = local.environment
  database_name      = "g4s-subject-history"
  path_to_data       = "/g4s_subject_history"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_tasking_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "tasking"
  environment        = local.environment
  database_name      = "g4s-tasking"
  path_to_data       = "/g4s_tasking"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_telephony_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "telephony"
  environment        = local.environment
  database_name      = "g4s-telephony"
  path_to_data       = "/g4s_telephony"
  source_data_bucket = module.s3-dms-target-store-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}

module "load_unstructured_atrium_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "unstructured-atrium"
  environment        = local.environment
  database_name      = "g4s-atrium-unstructured"
  path_to_data       = "/load/g4s_atrium_unstructured/structure"
  source_data_bucket = module.s3-json-directory-structure-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
}


module "load_fms" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "fms"
  environment        = local.environment
  database_name      = "serco-fms"
  path_to_data       = "/serco/fms"
  source_data_bucket = module.s3-raw-formatted-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  db_exists          = true
  new_airflow        = true
}


module "load_mdss" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "mdss"
  environment        = local.environment
  database_name      = "allied-mdss"
  path_to_data       = "/allied/mdss"
  source_data_bucket = module.s3-raw-formatted-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
}

module "load_scram_alcohol_monitoring_database" {
  count  = local.is-production || local.is-test ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "scram-alcohol-monitoring"
  environment        = local.environment
  database_name      = "scram-alcohol-monitoring"
  path_to_data       = "/scram/alcohol_monitoring"
  source_data_bucket = module.s3-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
}

module "full_reload_fms" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "fms"
  environment        = local.environment
  database_name      = "serco-fms"
  path_to_data       = "/serco/fms"
  source_data_bucket = module.s3-raw-formatted-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  db_exists          = true
  new_airflow        = true
  full_reload        = true
}

module "load_gps" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "gps"
  environment        = local.environment
  database_name      = "g4s-gps"
  path_to_data       = "/g4s/gps"
  source_data_bucket = module.s3-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
  full_reload        = true
}

module "inc_load_gps" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "gps"
  environment        = local.environment
  database_name      = "g4s-gps"
  path_to_data       = "/g4s/gps"
  source_data_bucket = module.s3-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
  db_exists          = true
}

module "full_reload_mdss" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "mdss"
  environment        = local.environment
  database_name      = "allied-mdss"
  path_to_data       = "/allied/mdss"
  source_data_bucket = module.s3-raw-formatted-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket

  db_exists   = true
  new_airflow = true
  full_reload = true
}

module "load_servicenow" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "servicenow"
  environment        = local.environment
  database_name      = "serco-servicenow"
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  secret_arn         = aws_secretsmanager_secret.servicenow_credentials.arn
  new_airflow        = true
}

module "full_reload_servicenow" {
  count  = local.is-development ? 0 : 1
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "servicenow"
  environment        = local.environment
  database_name      = "serco-servicenow"
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  secret_arn         = aws_secretsmanager_secret.servicenow_credentials.arn

  db_exists   = true
  new_airflow = true
  full_reload = true
}

module "load_capita_blob_storage" {
  count  = local.is-production || local.is-development ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "capita-blob-storage"
  environment        = local.environment
  database_name      = "capita-blob-storage"
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  source_data_bucket = module.s3-json-directory-structure-bucket.bucket
  new_airflow        = true
}

module "load_g4s_atrium_unstructured" {
  count  = local.is-production || local.is-development ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "g4s-atrium-unstructured"
  environment        = local.environment
  database_name      = "g4s-atrium-unstructured"
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  source_data_bucket = module.s3-json-directory-structure-bucket.bucket
  new_airflow        = true
}
module "load_integrity_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "integrity"
  environment          = local.environment
  database_name        = "g4s-integrity"
  path_to_data         = "/g4s_integrity"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60

  new_airflow = true
}

module "load_integrity_customdb_database" {
  count  = local.is-production ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name                 = "integrity-customdb"
  environment          = local.environment
  database_name        = "g4s-integrity-customdb"
  path_to_data         = "/g4s_integrity_customdb"
  source_data_bucket   = module.s3-dms-target-store-bucket.bucket
  secret_code          = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn             = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket   = module.s3-athena-bucket.bucket
  cadt_bucket          = module.s3-create-a-derived-table-bucket.bucket
  max_session_duration = 12 * 60 * 60

  new_airflow = true
}

module "load_buddi_database" {
  count  = local.is-production || local.is-test ? 1 : 0
  source = "./modules/ap_airflow_load_data_iam_role"

  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))

  name               = "buddi"
  environment        = local.environment
  database_name      = "buddi"
  path_to_data       = "/buddi/buddi"
  source_data_bucket = module.s3-data-bucket.bucket
  secret_code        = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn           = aws_iam_openid_connect_provider.analytical_platform_compute.arn
  athena_dump_bucket = module.s3-athena-bucket.bucket
  cadt_bucket        = module.s3-create-a-derived-table-bucket.bucket
  new_airflow        = true
}
