locals {
  lambda_path = "lambdas"
  env_name    = local.is-production ? "prod" : "dev"
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

#-----------------------------------------------------------------------------------
# Process json files
#-----------------------------------------------------------------------------------

module "format_json_fms_data" {
  source                  = "./modules/lambdas"
  function_name           = "format_json_fms_data"
  is_image                = true
  role_name               = aws_iam_role.format_json_fms_data.name
  role_arn                = aws_iam_role.format_json_fms_data.arn
  memory_size             = 1024
  timeout                 = 900
  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : "dev"
}

#-----------------------------------------------------------------------------------
# Calculate checksum
#-----------------------------------------------------------------------------------

variable "checksum_algorithm" {
  type        = string
  description = "Select Checksum Algorithm. Default and recommended choice is SHA256, however CRC32, CRC32C, SHA1 are also available."
  default     = "SHA256"
}

data "archive_file" "calculate_checksum_lambda" {
  type        = "zip"
  source_file = "${local.lambda_path}/calculate_checksum_lambda.py"
  output_path = "${local.lambda_path}/calculate_checksum_lambda.zip"
}

module "calculate_checksum_lambda" {
  source           = "./modules/lambdas"
  filename         = "${local.lambda_path}/calculate_checksum_lambda.zip"
  function_name    = "calculate_checksum_lambda"
  role_name        = aws_iam_role.calculate_checksum_lambda.arn
  role_arn         = aws_iam_role.calculate_checksum_lambda.arn
  handler          = "calculate_checksum_lambda.handler"
  runtime          = "python3.12"
  memory_size      = 4096
  timeout          = 900
  source_code_hash = data.archive_file.get_metadata_from_rds.output_base64sha256
  environment_variables = {
    Checksum = var.checksum_algorithm
  }
}

resource "aws_lambda_permission" "allow_sns_invoke_checksum_lambda" {
  statement_id  = "AllowSNSInvokeChecksum"
  action        = "lambda:InvokeFunction"
  function_name = module.calculate_checksum_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3_events.arn
}

resource "aws_sns_topic_subscription" "checksum_lambda_subscription" {
  topic_arn = aws_sns_topic.s3_events.arn
  protocol  = "lambda"
  endpoint  = module.calculate_checksum_lambda.lambda_function_arn

  depends_on = [aws_lambda_permission.allow_sns_invoke_checksum_lambda]
}

#------------------------------------------------------------------------------
# S3 lambda function to perform zip file summary
#------------------------------------------------------------------------------

data "archive_file" "summarise_zip_lambda" {
  type        = "zip"
  source_file = "lambdas/summarise_zip_lambda.py"
  output_path = "lambdas/summarise_zip_lambda.zip"
}

module "summarise_zip_lambda" {
  source           = "./modules/lambdas"
  filename         = "${local.lambda_path}/summarise_zip_lambda.zip"
  function_name    = "summarise_zip_lambda"
  role_name        = aws_iam_role.summarise_zip_lambda.arn
  role_arn         = aws_iam_role.summarise_zip_lambda.arn
  handler          = "summarise_zip_lambda.handler"
  runtime          = "python3.12"
  memory_size      = 4096
  timeout          = 900
  source_code_hash = data.archive_file.summarise_zip_lambda.output_base64sha256
}


resource "aws_lambda_permission" "allow_sns_invoke_zip_lambda" {
  statement_id  = "AllowSNSInvokeZip"
  action        = "lambda:InvokeFunction"
  function_name = module.summarise_zip_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3_events.arn
}


resource "aws_sns_topic_subscription" "zip_lambda_subscription" {
  topic_arn = aws_sns_topic.s3_events.arn
  protocol  = "lambda"
  endpoint  = module.summarise_zip_lambda.lambda_function_arn

  depends_on = [aws_lambda_permission.allow_sns_invoke_zip_lambda]
}
