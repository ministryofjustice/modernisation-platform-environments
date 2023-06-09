##########################
#    Domain Builder TF   # 
##########################
locals {
   dpr_vpc = data.aws_vpc.shared.id
   dpr_subnets = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
   rds_kms_arn = aws_kms_key.rds.arn    
   enable_domain_builder_rds = local.application_data.accounts[local.environment].enable_domain_builder_rds
   rds_dbuilder_name = "${local.project}_backend_rds"
   rds_dbuilder_db_identifier = "${local.project}-domain-builder"
   rds_dbuilder_inst_class = "db.t3.small"
   rds_dbuilder_store_type = "gp2"
   rds_dbuilder_init_size = 10
   rds_dbuilder_max_size = 50
   rds_dbuilder_parameter_group = "postgres14"
   rds_dbuilder_port = 5432
   rds_dbuilder_user = "domain_builder"
   enable_dbuilder_lambda = local.application_data.accounts[local.environment].enable_domain_builder_lambda
   lambda_dbuilder_name = "${local.project}-domain-builder-backend-api"
   lambda_dbuilder_runtime = "java11"
   lambda_dbuilder_tracing = "Active"
   lambda_dbuilder_handler = "io.micronaut.function.aws.proxy.MicronautLambdaHandler"
   lambda_dbuilder_code_s3_bucket = module.s3_artifacts_store.bucket_id
   lambda_dbuilder_code_s3_key = "build-artifacts/domain-builder/jars/domain-builder-backend-api-vLatest-all.jar"
   lambda_dbuilder_policies = [aws_iam_policy.s3_read_access_policy.arn, ]
}

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
      ResourceGroup = "${local.project}-domain-builder-backend-${local.environment}"
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
      ResourceGroup = "${local.project}-domain-builder-backend-${local.environment}"
      Jira           = "DPR-407"
    }
  )
}