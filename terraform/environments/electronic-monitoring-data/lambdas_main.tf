locals {
  lambda_path = "lambdas"
  env_name    = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
  db_name     = local.is-production ? "g4s_cap_dw" : "test"
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
  security_group_ids      = [aws_security_group.lambda_generic.id]
  subnet_ids              = data.aws_subnets.shared-public.ids
  environment_variables = {
    OUTPUT_BUCKET = module.s3-json-directory-structure-bucket.bucket.id
    SOURCE_BUCKET = module.s3-data-bucket.bucket.id
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
  security_group_ids      = [aws_security_group.lambda_generic.id]
  subnet_ids              = data.aws_subnets.shared-public.ids
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
  security_group_ids      = [aws_security_group.lambda_generic.id]
  subnet_ids              = data.aws_subnets.shared-public.ids
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
# Virus scanning - definition upload
#-----------------------------------------------------------------------------------

module "virus_scan_definition_upload" {
  source        = "./modules/lambdas"
  function_name = "definition-upload"
  is_image      = true
  ecr_repo_name = "analytical-platform-ingestion-scan"
  function_tag  = "0.2.0"
  role_name     = aws_iam_role.virus_scan_definition_upload.name
  role_arn      = aws_iam_role.virus_scan_definition_upload.arn
  memory_size   = 2048
  timeout       = 900
  # security_group_ids      = [aws_security_group.lambda_generic.id]
  # subnet_ids              = data.aws_subnets.shared-public.ids
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
  source                         = "./modules/lambdas"
  function_name                  = "scan"
  is_image                       = true
  ecr_repo_name                  = "analytical-platform-ingestion-scan"
  function_tag                   = "v0.2.0-rc4"
  role_name                      = aws_iam_role.virus_scan_file.name
  role_arn                       = aws_iam_role.virus_scan_file.arn
  ephemeral_storage_size         = 10240
  memory_size                    = 2048
  timeout                        = 900
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  reserved_concurrent_executions = 1000
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  environment_variables = {
    MODE                         = "scan",
    CLAMAV_DEFINITON_BUCKET_NAME = module.s3-clamav-definitions-bucket.bucket.id
    LANDING_BUCKET_NAME          = module.s3-received-files-bucket.bucket.id
    QUARANTINE_BUCKET_NAME       = module.s3-quarantine-files-bucket.bucket.id
    PROCESSED_BUCKET_NAME        = module.s3-data-bucket.bucket.id
  }
}

#-----------------------------------------------------------------------------------
# Process live files
#-----------------------------------------------------------------------------------

module "format_json_fms_data" {
  source                         = "./modules/lambdas"
  function_name                  = "format_json_fms_data"
  is_image                       = true
  role_name                      = aws_iam_role.format_json_fms_data.name
  role_arn                       = aws_iam_role.format_json_fms_data.arn
  memory_size                    = 1024
  timeout                        = 900
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : "dev"
  reserved_concurrent_executions = 1000
  environment_variables = {
    DESTINATION_BUCKET = module.s3-raw-formatted-data-bucket.bucket.id
  }
}

module "copy_mdss_data" {
  source                         = "./modules/lambdas"
  function_name                  = "copy_mdss_data"
  image_name                     = "copy_data"
  is_image                       = true
  role_name                      = aws_iam_role.copy_mdss_data.name
  role_arn                       = aws_iam_role.copy_mdss_data.arn
  memory_size                    = 1024
  timeout                        = 900
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  reserved_concurrent_executions = 1000
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : "dev"
  environment_variables = {
    DESTINATION_BUCKET = module.s3-raw-formatted-data-bucket.bucket.id
  }
}

#-----------------------------------------------------------------------------------
# Clean after MDSS load
#-----------------------------------------------------------------------------------

module "clean_after_dlt_load" {
  count                          = local.is-development ? 0 : 1
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "clean_after_dlt_load"
  role_name                      = aws_iam_role.clean_after_dlt_load[0].name
  role_arn                       = aws_iam_role.clean_after_dlt_load[0].arn
  handler                        = "clean_after_dlt_load.handler"
  memory_size                    = 2048
  timeout                        = 900
  reserved_concurrent_executions = 100
  ephemeral_storage_size         = 10240
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids

  environment_variables = {
    CATALOG_ID      = data.aws_caller_identity.current.account_id
    LAMBDA_ROLE_ARN = aws_iam_role.clean_after_dlt_load[0].arn
  }
}

#-----------------------------------------------------------------------------------
# Calculate checksum
#-----------------------------------------------------------------------------------

variable "checksum_algorithm" {
  type        = string
  description = "Select Checksum Algorithm. Default and recommended choice is SHA256, however CRC32, CRC32C, SHA1 are also available."
  default     = "SHA256"
}

module "calculate_checksum" {
  source                  = "./modules/lambdas"
  is_image                = true
  function_name           = "calculate_checksum"
  role_name               = aws_iam_role.calculate_checksum.name
  role_arn                = aws_iam_role.calculate_checksum.arn
  handler                 = "calculate_checksum.handler"
  memory_size             = 4096
  timeout                 = 900
  security_group_ids      = [aws_security_group.lambda_generic.id]
  subnet_ids              = data.aws_subnets.shared-public.ids
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
  environment_variables = {
    Checksum = var.checksum_algorithm
  }

}

#-----------------------------------------------------------------------------------
# DMS Validation Lambdas
#-----------------------------------------------------------------------------------
module "dms_retrieve_metadata" {
  count = local.is-development || local.is-production ? 1 : 0

  source                  = "./modules/lambdas"
  is_image                = true
  function_name           = "dms_retrieve_metadata"
  role_name               = aws_iam_role.dms_validation_lambda_role[0].name
  role_arn                = aws_iam_role.dms_validation_lambda_role[0].arn
  handler                 = "dms_retrieve_metadata.handler"
  memory_size             = 10240
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"

  environment_variables = {
    SOURCE_BUCKET = module.s3-dms-target-store-bucket.bucket.id
  }

  security_group_ids = [aws_security_group.dms_validation_lambda_sg[0].id]
  subnet_ids         = data.aws_subnets.shared-public.ids
}


module "dms_validation" {
  count = local.is-development || local.is-production ? 1 : 0

  source                  = "./modules/lambdas"
  is_image                = true
  function_name           = "dms_validation"
  role_name               = aws_iam_role.dms_validation_lambda_role[0].name
  role_arn                = aws_iam_role.dms_validation_lambda_role[0].arn
  handler                 = "dms_validation.handler"
  memory_size             = 10240
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"

  environment_variables = {
    SOURCE_BUCKET = module.s3-dms-target-store-bucket.bucket.id
    SECRET_NAME   = aws_secretsmanager_secret.db_password[0].name
    USER          = aws_db_instance.database_2022[0].username
    SERVER_NAME   = split(":", aws_db_instance.database_2022[0].endpoint)[0]
  }

  security_group_ids = [aws_security_group.dms_validation_lambda_sg[0].id]
  subnet_ids         = data.aws_subnets.shared-public.ids
}

#-----------------------------------------------------------------------------------
# Process FMS metadata
#-----------------------------------------------------------------------------------

module "process_fms_metadata" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "process_fms_metadata"
  role_name                      = aws_iam_role.process_fms_metadata.name
  role_arn                       = aws_iam_role.process_fms_metadata.arn
  handler                        = "process_fms_metadata.handler"
  memory_size                    = 10240
  timeout                        = 900
  reserved_concurrent_executions = 1000
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  environment_variables = {
    SQS_QUEUE_URL                = aws_sqs_queue.format_fms_json_event_queue.id
    POWERTOOLS_METRICS_NAMESPACE = "FMSLiveFeed"
    POWERTOOLS_SERVICE_NAME      = "process-fms-metadata-lambda"
  }
}

#-----------------------------------------------------------------------------------
# dlt load dms output
#-----------------------------------------------------------------------------------

module "load_dms_output" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "load_dms_output"
  role_name                      = aws_iam_role.load_dms_output.name
  role_arn                       = aws_iam_role.load_dms_output.arn
  handler                        = "load_dms_output.handler"
  memory_size                    = 10240
  timeout                        = 900
  reserved_concurrent_executions = 100
  ephemeral_storage_size         = 10240
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  environment_variables = {
    ATHENA_QUERY_BUCKET = module.s3-athena-bucket.bucket.id
    ACCOUNT_NUMBER      = data.aws_caller_identity.current.account_id
    STAGING_BUCKET      = module.s3-create-a-derived-table-bucket.bucket.id
  }
}


#-----------------------------------------------------------------------------------
# dlt load mdss
#-----------------------------------------------------------------------------------

module "load_mdss_lambda" {
  count                          = local.is-development ? 0 : 1
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "load_mdss"
  role_name                      = aws_iam_role.load_mdss[0].name
  role_arn                       = aws_iam_role.load_mdss[0].arn
  handler                        = "load_mdss.handler"
  memory_size                    = 10240
  timeout                        = 900
  reserved_concurrent_executions = 500
  ephemeral_storage_size         = 10240
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  cloudwatch_retention_days      = 7
  environment_variables = {
    ATHENA_QUERY_BUCKET = module.s3-athena-bucket.bucket.id
    ACCOUNT_NUMBER      = data.aws_caller_identity.current.account_id
    STAGING_BUCKET      = module.s3-create-a-derived-table-bucket.bucket.id
    ENVIRONMENT_NAME    = local.environment_shorthand
    CLEANUP_QUEUE_URL   = aws_sqs_queue.clean_dlt_load_queue.id
  }
}

#-----------------------------------------------------------------------------------
# dlt load fms
#-----------------------------------------------------------------------------------

module "load_fms_lambda" {
  count                          = local.is-development ? 0 : 1
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "load_fms"
  role_name                      = aws_iam_role.load_fms[0].name
  role_arn                       = aws_iam_role.load_fms[0].arn
  handler                        = "load_fms.handler"
  memory_size                    = 10240
  timeout                        = 900
  reserved_concurrent_executions = 500
  ephemeral_storage_size         = 10240
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  cloudwatch_retention_days      = 7
  environment_variables = {
    ATHENA_QUERY_BUCKET = module.s3-athena-bucket.bucket.id
    ACCOUNT_NUMBER      = data.aws_caller_identity.current.account_id
    STAGING_BUCKET      = module.s3-create-a-derived-table-bucket.bucket.id
    ENVIRONMENT_NAME    = local.environment_shorthand
    CLEANUP_QUEUE_URL   = aws_sqs_queue.clean_dlt_load_queue.id
  }
}

#-----------------------------------------------------------------------------------
# dlt load csv
#-----------------------------------------------------------------------------------

module "load_historic_csv" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "load_historic_csv"
  role_name                      = aws_iam_role.load_historic_csv.name
  role_arn                       = aws_iam_role.load_historic_csv.arn
  handler                        = "load_historic_csv.handler"
  memory_size                    = 10240
  timeout                        = 900
  reserved_concurrent_executions = 500
  ephemeral_storage_size         = 10240
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids
  environment_variables = {
    ATHENA_QUERY_BUCKET = module.s3-athena-bucket.bucket.id
    ACCOUNT_NUMBER      = data.aws_caller_identity.current.account_id
    STAGING_BUCKET      = module.s3-create-a-derived-table-bucket.bucket.id
    ENVIRONMENT_NAME    = local.environment_shorthand
    DB_SUFFIX           = local.db_suffix
  }
}

#-----------------------------------------------------------------------------------
# Glue DB count metrics Lambda (publishes CloudWatch metric)
#-----------------------------------------------------------------------------------

module "glue_db_count_metrics" {
  count                          = local.is-development ? 0 : 1
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "glue_db_count_metrics"
  role_name                      = aws_iam_role.glue_db_count_metrics.name
  role_arn                       = aws_iam_role.glue_db_count_metrics.arn
  handler                        = "glue_db_count_metrics.handler"
  memory_size                    = 1024
  timeout                        = 300
  reserved_concurrent_executions = 1
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.env_name
  security_group_ids             = [aws_security_group.lambda_generic.id]
  subnet_ids                     = data.aws_subnets.shared-public.ids

  environment_variables = {
    METRIC_NAMESPACE = "EMDS/Glue"
    METRIC_NAME      = "GlueDatabaseCount"
    ENVIRONMENT      = local.environment_shorthand
  }
}

#-----------------------------------------------------------------------------------
# Schedule Glue DB count metrics Lambda
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "glue_db_count_metrics_schedule" {
  count               = local.is-development ? 0 : 1
  name                = "glue_db_count_metrics_schedule"
  description         = "Runs glue_db_count_metrics on a schedule to publish Glue database count"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "glue_db_count_metrics_target" {
  count = local.is-development ? 0 : 1
  rule  = aws_cloudwatch_event_rule.glue_db_count_metrics_schedule[0].name
  arn   = module.glue_db_count_metrics[0].lambda_function_arn
}

resource "aws_lambda_permission" "glue_db_count_metrics_allow_eventbridge" {
  count         = local.is-development ? 0 : 1
  statement_id  = "AllowExecutionFromEventBridgeGlueDbCount"
  action        = "lambda:InvokeFunction"
  function_name = module.glue_db_count_metrics[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_db_count_metrics_schedule[0].arn
}
