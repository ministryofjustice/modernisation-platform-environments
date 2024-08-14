locals {
  dataset_name_parts = split("_",  v)
  SUPPLIER_NAME      = local.dataset_name_parts[0]
  SYSTEM_NAME        = join("_", slice(local.dataset_name_parts, 1, length(local.dataset_name_parts)))
}

module "this" {
  source                  = "./modules/lambdas"
  function_name           = "load_${var.dataset_name}"
  is_image                = true
  role_name               = var.iam_role.name
  role_arn                = var.iam_role.arn
  memory_size             = var.memory_size
  timeout                 = var.timeout
  env_account_id          = local.env_account_id
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  ecr_repo_name           = "create-a-data-task"
  function_tag            = var.function_tag
  environment_variables = {
    DLT_PROJECT_DIR : "/tmp"
    DLT_DATA_DIR : "/tmp"
    DLT_PIPELINE_DIR : "/tmp"
    JSON_BUCKET_NAME                         = module.json-directory-structure-bucket.bucket.id
    STANDARD_FILESYSTEM__QUERY_RESULT_BUCKET = "s3://${module.athena-s3-bucket.bucket.id}/output"
    ATHENA_DUMP_BUCKET_NAME                  = module.metadata-s3-bucket.bucket.id
    pipeline_name                            = var.dataset_name
    environment                              = local.is-production ? "prod" : "dev"
    SUPPLIER_NAME                            = SUPPLIER_NAME
    SYSTEM_NAME                              = SYSTEM_NAME
  }
}
