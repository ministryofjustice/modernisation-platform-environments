#### This file can be used to store locals specific to the member account ####
locals {
  lambda_runtime            = "python3.9"
  lambda_timeout_in_seconds = 15
  region                    = "eu-west-2"
  account_id                = local.environment_management.account_ids[terraform.workspace]
  api_auth_token            = jsondecode(data.aws_secretsmanager_secret_version.api_auth.secret_string)["auth-token"]


  # Glue
  glue_default_arguments = {
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
    "--enable-job-insights"              = "true"
    "--enable-continuous-log-filter"     = "true"
  }
  name                             = "data-platform-product"
  glue_version                     = "4.0"
  max_retries                      = 0
  worker_type                      = "G.1X"
  number_of_workers                = 2
  timeout                          = 120 # minutes
  execution_class                  = "STANDARD"
  max_concurrent                   = 5
  glue_log_group_retention_in_days = 7

  docs_version                          = lookup(var.docs_versions, local.environment)
  authorizer_version                    = lookup(var.authorizer_versions, local.environment)
  get_glue_metadata_version             = lookup(var.get_glue_metadata_versions, local.environment)
  presigned_url_version                 = lookup(var.presigned_url_versions, local.environment)
  athena_load_version                   = lookup(var.athena_load_versions, local.environment)
  create_metadata_version               = lookup(var.create_metadata_versions, local.environment)
  resync_unprocessed_files_version      = lookup(var.resync_unprocessed_files_versions, local.environment)
  reload_data_product_version           = lookup(var.reload_data_product_versions, local.environment)
  get_schema_version                    = lookup(var.get_schema_versions, local.environment)
  create_schema_version                 = lookup(var.create_schema_versions, local.environment)
  landing_to_raw_version                = lookup(var.landing_to_raw_versions, local.environment)
  update_metadata_version               = lookup(var.update_metadata_versions, local.environment)
  update_schema_version                 = lookup(var.update_schema_versions, local.environment)
  preview_data_version                  = lookup(var.preview_data_versions, local.environment)
  delete_table_for_data_product_version = lookup(var.delete_table_for_data_product_versions, local.environment)

  # Environment vars that are used by many lambdas
  logger_environment_vars = {
    LOG_BUCKET = module.logs_s3_bucket.bucket.id
  }

  storage_environment_vars = {
    RAW_DATA_BUCKET     = module.data_s3_bucket.bucket.id
    CURATED_DATA_BUCKET = module.data_s3_bucket.bucket.id
    METADATA_BUCKET     = module.metadata_s3_bucket.bucket.id
    LANDING_ZONE_BUCKET = module.data_landing_s3_bucket.bucket.id
  }
}
