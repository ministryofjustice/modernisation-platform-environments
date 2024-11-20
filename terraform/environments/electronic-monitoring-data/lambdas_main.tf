locals {
  lambda_path = "lambdas"
  env_name    = local.is-production ? "prod" : "dev"
  db_name     = local.is-production ? "g4s_cap_dw" : "test"
}

# ------------------------------------------------------
# Get Metadata from RDS Function
# ------------------------------------------------------

data "archive_file" "get_metadata_from_rds" {
  type        = "zip"
  source_file = "${local.lambda_path}/get_metadata_from_rds.py"
  output_path = "${local.lambda_path}/get_metadata_from_rds.zip"
}

#checkov:skip=CKV_AWS_272
module "get_metadata_from_rds_lambda" {
  source        = "./modules/lambdas"
  filename      = "${local.lambda_path}/get_metadata_from_rds.zip"
  function_name = "get-metadata-from-rds"
  role_arn      = aws_iam_role.get_metadata_from_rds.arn
  role_name     = aws_iam_role.get_metadata_from_rds.name
  handler       = "get_metadata_from_rds.handler"
  layers = [
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
    aws_lambda_layer_version.mojap_metadata_layer.arn,
    aws_lambda_layer_version.create_athena_table_layer.arn
  ]
  source_code_hash   = data.archive_file.get_metadata_from_rds.output_base64sha256
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  environment_variables = {
    SECRET_NAME           = aws_secretsmanager_secret.db_glue_connection.name
    METADATA_STORE_BUCKET = module.s3-metadata-bucket.bucket.id
  }
}



# ------------------------------------------------------
# Create Individual Athena Semantic Layer Function
# ------------------------------------------------------


data "archive_file" "create_athena_table" {
  type        = "zip"
  source_file = "${local.lambda_path}/create_athena_table.py"
  output_path = "${local.lambda_path}/create_athena_table.zip"
}

module "create_athena_table" {
  source   = "./modules/lambdas"
  filename = "${local.lambda_path}/create_athena_table.zip"

  function_name = "create_athena_table"
  role_arn      = aws_iam_role.create_athena_table_lambda.arn
  role_name     = aws_iam_role.create_athena_table_lambda.name
  handler       = "create_athena_table.handler"
  layers = [
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:69",
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
    aws_lambda_layer_version.mojap_metadata_layer.arn,
    aws_lambda_layer_version.create_athena_table_layer.arn
  ]
  source_code_hash   = data.archive_file.create_athena_table.output_base64sha256
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  environment_variables = {
    S3_BUCKET_NAME = module.s3-dms-target-store-bucket.bucket.id
  }
}

# ------------------------------------------------------
# get file keys for table
# ------------------------------------------------------


data "archive_file" "get_file_keys_for_table" {
  type        = "zip"
  source_file = "${local.lambda_path}/get_file_keys_for_table.py"
  output_path = "${local.lambda_path}/get_file_keys_for_table.zip"
}

module "get_file_keys_for_table" {
  source             = "./modules/lambdas"
  filename           = "${local.lambda_path}/get_file_keys_for_table.zip"
  function_name      = "get_file_keys_for_table"
  role_arn           = aws_iam_role.get_file_keys_for_table.arn
  role_name          = aws_iam_role.get_file_keys_for_table.name
  handler            = "get_file_keys_for_table.handler"
  source_code_hash   = data.archive_file.get_file_keys_for_table.output_base64sha256
  layers             = null
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  environment_variables = {
    PARQUET_BUCKET_NAME = module.s3-dms-target-store-bucket.bucket.id
  }
}

# ------------------------------------------------------
# Get Tables from DB
# ------------------------------------------------------


data "archive_file" "query_output_to_list" {
  type        = "zip"
  source_file = "${local.lambda_path}/query_output_to_list.py"
  output_path = "${local.lambda_path}/query_output_to_list.zip"
}

module "query_output_to_list" {
  source                = "./modules/lambdas"
  filename              = "${local.lambda_path}/query_output_to_list.zip"
  function_name         = "query_output_to_list"
  role_arn              = aws_iam_role.query_output_to_list.arn
  role_name             = aws_iam_role.query_output_to_list.name
  handler               = "query_output_to_list.handler"
  source_code_hash      = data.archive_file.query_output_to_list.output_base64sha256
  layers                = null
  timeout               = 900
  memory_size           = 1024
  runtime               = "python3.11"
  security_group_ids    = null
  subnet_ids            = null
  environment_variables = null
}

# ------------------------------------------------------
# Update log table
# ------------------------------------------------------

module "update_log_table" {
  source                  = "./modules/lambdas"
  function_name           = "update_log_table"
  is_image                = true
  role_name               = aws_iam_role.update_log_table.name
  role_arn                = aws_iam_role.update_log_table.arn
  memory_size             = 1024
  timeout                 = 899
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  environment_variables = {
    S3_LOG_BUCKET = module.s3-dms-data-validation-bucket.bucket.id
    DATABASE_NAME = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    TABLE_NAME    = "glue_df_output"
  }
}

#-----------------------------------------------------------------------------------
# S3 lambda function to perform zip file structure extraction into json for Athena
#-----------------------------------------------------------------------------------

module "output_file_structure_as_json_from_zip" {
  source                  = "./modules/lambdas"
  function_name           = "extract_metadata_from_atrium_unstructured"
  is_image                = true
  role_name               = aws_iam_role.extract_metadata_from_atrium_unstructured.name
  role_arn                = aws_iam_role.extract_metadata_from_atrium_unstructured.arn
  memory_size             = 1024
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  security_group_ids      = [aws_security_group.lambda_db_security_group.id]
  subnet_ids              = data.aws_subnets.shared-public.ids
  environment_variables = {
    OUTPUT_BUCKET = module.s3-json-directory-structure-bucket.bucket.id
    SOURCE_BUCKET = module.s3-data-bucket.bucket.id
  }
}

#-----------------------------------------------------------------------------------
# Load data from S3 to Athena
#-----------------------------------------------------------------------------------

module "load_unstructured_structure" {
  source                  = "./modules/lambdas"
  function_name           = "load_unstructured_structure"
  is_image                = true
  role_name               = aws_iam_role.load_json_table.name
  role_arn                = aws_iam_role.load_json_table.arn
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  environment_variables = {
    DLT_PROJECT_DIR : "/tmp"
    DLT_DATA_DIR : "/tmp"
    DLT_PIPELINE_DIR : "/tmp"
    JSON_BUCKET_NAME        = module.s3-json-directory-structure-bucket.bucket.id
    ATHENA_DUMP_BUCKET_NAME = module.s3-athena-bucket.bucket.id
  }
}


#-----------------------------------------------------------------------------------
# Unzip single file
#-----------------------------------------------------------------------------------

module "unzip_single_file" {
  source                  = "./modules/lambdas"
  function_name           = "unzip_single_file"
  is_image                = true
  role_name               = aws_iam_role.unzip_single_file.name
  role_arn                = aws_iam_role.unzip_single_file.arn
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  environment_variables = {
    BUCKET_NAME        = module.s3-data-bucket.bucket.id
    EXPORT_BUCKET_NAME = module.s3-unzipped-files-bucket.bucket.id
  }
}

#-----------------------------------------------------------------------------------
# Create pre signed url
#-----------------------------------------------------------------------------------

module "unzipped_presigned_url" {
  source                  = "./modules/lambdas"
  function_name           = "unzipped_presigned_url"
  is_image                = true
  role_name               = aws_iam_role.unzipped_presigned_url.name
  role_arn                = aws_iam_role.unzipped_presigned_url.arn
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
}

#-----------------------------------------------------------------------------------
# Rotate IAM keys
#-----------------------------------------------------------------------------------

module "rotate_iam_key" {
  source                  = "./modules/lambdas"
  function_name           = "rotate_iam_key"
  is_image                = true
  role_name               = aws_iam_role.rotate_iam_keys.name
  role_arn                = aws_iam_role.rotate_iam_keys.arn
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
}

#-----------------------------------------------------------------------------------
# Process landing bucket files
#-----------------------------------------------------------------------------------

module "process_landing_bucket_files" {
  source                  = "./modules/lambdas"
  function_name           = "process_landing_bucket_files"
  is_image                = true
  role_name               = aws_iam_role.process_landing_bucket_files.name
  role_arn                = aws_iam_role.process_landing_bucket_files.arn
  memory_size             = 1024
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  environment_variables = {
    DESTINATION_BUCKET = module.s3-received-files-bucket.bucket.id
  }
}

#-----------------------------------------------------------------------------------
# Virus scanning - definition upload
#-----------------------------------------------------------------------------------

module "virus_scan_definition_upload" {
  source                  = "./modules/lambdas"
  function_name           = "definition-upload"
  is_image                = true
  ecr_repo_name           = "analytical-platform-ingestion-scan"
  function_tag            = "0.1.0"
  role_name               = aws_iam_role.virus_scan_definition_upload.name
  role_arn                = aws_iam_role.virus_scan_definition_upload.arn
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  environment_variables = {
    MODE                         = "definition-upload",
    CLAMAV_DEFINITON_BUCKET_NAME = module.s3-clamav-definitions-bucket.bucket.id
  }
}

resource "aws_lambda_permission" "virus_scan_definition_upload_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.virus_scan_definition_upload.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.definition_update.arn
}

#-----------------------------------------------------------------------------------
# Virus scanning - file scan
#-----------------------------------------------------------------------------------

module "virus_scan_file" {
  source                  = "./modules/lambdas"
  function_name           = "scan"
  is_image                = true
  ecr_repo_name           = "analytical-platform-ingestion-scan"
  function_tag            = "0.1.0"
  role_name               = aws_iam_role.virus_scan_file.name
  role_arn                = aws_iam_role.virus_scan_file.arn
  ephemeral_storage_size  = 10240
  memory_size             = 2048
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  environment_variables = {
    MODE                         = "scan",
    CLAMAV_DEFINITON_BUCKET_NAME = module.s3-clamav-definitions-bucket.bucket.id
    LANDING_BUCKET_NAME          = module.s3-received-files-bucket.bucket.id
    QUARANTINE_BUCKET_NAME       = module.s3-quarantine-files-bucket.bucket.id
    PROCESSED_BUCKET_NAME        = module.s3-data-bucket.bucket.id
  }
}
