##########################
#    Domain Builder TF   # 
##########################
# Domain Builder Backend Lambda function
module "domain_builder_backend_Lambda" {
  source    = "./modules/lambdas/generic"

  enable_lambda = local.enable_dbuilder_lambda
  name          = local.lambda_dbuilder_name
  s3_bucket     = local.lambda_dbuilder_code_s3_bucket
  s3_key        = local.lambda_dbuilder_code_s3_key
  handler       = local.lambda_dbuilder_handler
  runtime       = local.lambda_dbuilder_runtime
  policies      = local.lambda_dbuilder_policies
  tracing       = local.lambda_dbuilder_tracing
  env_vars = {
    "JAVA_TOOL_OPTIONS" = "-XX:MetaspaceSize=32m"
    "POSTGRES_HOST" = module.domain_builder_backend_db.rds_host
    "POSTGRES_DB_NAME" = local.rds_dbuilder_db_identifier
    "POSTGRES_USERNAME" = local.rds_dbuilder_user
    "POSTGRES_PASSWORD" = module.domain_builder_backend_db.master_password
    "POSTGRES_PORT" = local.rds_dbuilder_port
  }

  tags = merge(
    local.all_tags,
    {
      Resource_Group = "${local.project}-domain-builder-backend-${local.environment}"
      Jira          = "DPR-407"
    }
  )
}

# Domain Builder RDS Instance
module "domain_builder_backend_db" {
  source     = "./modules/rds/postgres"

  enable_rds            = local.enable_domain_builder_rds
  allocated_size        = local.rds_dbuilder_init_size
  max_allocated_size    = local.rds_dbuilder_max_size
  subnets               = local.dpr_subnets
  vpc_id                = local.dpr_vpc
  kms                   = local.rds_kms_arn
  name                  = local.rds_dbuilder_name
  db_name               = local.rds_dbuilder_db_identifier
  db_instance_class     = local.rds_dbuilder_inst_class
  master_user           = local.rds_dbuilder_user
  storage_type          = local.rds_dbuilder_store_type
  parameter_group       = local.rds_dbuilder_parameter_group     
  
  tags = merge(
    local.all_tags,
    {
      Resource_Group = "${local.project}-domain-builder-backend-${local.environment}"
      Jira           = "DPR-407"
    }
  )
}