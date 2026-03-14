# Shamelessly borrowed from EMs virus scan setup

locals {
  lambda_path                     = "lambdas"
  env_name                        = local.is-production ? "prod" : local.is-development ? "test" : "dev"
  db_name                         = local.is-production ? "genesys-opg-prod" : local.is-development ? "genesys-opg-dev" : "genesys-opg-test"
  load_sqs_max_receive_count      = 2
  load_mdss_sqs_max_receive_count = 8
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
  # subnet_ids              = data.aws_subnets.shared-private.ids
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
  subnet_ids                     = data.aws_subnets.shared-private.ids
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
