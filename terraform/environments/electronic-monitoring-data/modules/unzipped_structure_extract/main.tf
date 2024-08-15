locals {
  dataset_name_parts = split("_",  var.dataset_name)
  SUPPLIER_NAME      = local.dataset_name_parts[0]
  SYSTEM_NAME        = join("_", slice(local.dataset_name_parts, 1, length(local.dataset_name_parts)))
}

module "this" {
  source                  = "../lambdas"
  function_name           = "load_${var.dataset_name}"
  is_image                = true
  role_name               = var.iam_role.name
  role_arn                = var.iam_role.arn
  memory_size             = var.memory_size
  timeout                 = var.timeout
  env_account_id          = var.env_account_id
  core_shared_services_id = var.core_shared_services_id
  production_dev          = var.production_dev
  ecr_repo_name           = "create-a-data-task"
  function_tag            = var.function_tag
  environment_variables = {
    DLT_PROJECT_DIR : "/tmp"
    DLT_DATA_DIR : "/tmp"
    DLT_PIPELINE_DIR : "/tmp"
    JSON_BUCKET_NAME                         = var.json_bucket_name
    STANDARD_FILESYSTEM__QUERY_RESULT_BUCKET = "s3://${var.athena_bucket_name}/output"
    ATHENA_DUMP_BUCKET_NAME                  = var.athena_bucket_name
    pipeline_name                            = var.dataset_name
    environment                              = var.production_dev
    SUPPLIER_NAME                            = local.SUPPLIER_NAME
    SYSTEM_NAME                              = local.SYSTEM_NAME
  }
}
