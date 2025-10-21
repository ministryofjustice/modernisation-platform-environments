##########################
#    Domain Builder TF   # 
##########################
# Generate API Secret for Serverless Lambda Gateway
module "domain_builder_api_key" {
  count = local.enable_dbuilder_lambda || local.enable_domain_builder_agent ? 1 : 0

  source                  = "./modules/secrets_manager"
  name                    = "${local.project}-domain-api-key-${local.environment}"
  description             = "Serverless Lambda GW API Key"
  length                  = 20
  override_special        = "{};<>?,./"
  generate_random         = true
  recovery_window_in_days = 0
  pass_version            = 1

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR-604"
      dpr-resource-type  = "Secret"
      dpr-name           = "${local.project}-domain-api-key-${local.environment}"
    }
  )
}

# Domain Builder Backend Lambda function
module "domain_builder_backend_Lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda = local.enable_dbuilder_lambda
  name          = local.lambda_dbuilder_name
  s3_bucket     = local.lambda_dbuilder_code_s3_bucket
  s3_key        = local.lambda_dbuilder_code_s3_key
  handler       = local.lambda_dbuilder_handler
  runtime       = local.lambda_dbuilder_runtime
  policies      = local.lambda_dbuilder_policies
  tracing       = local.lambda_dbuilder_tracing
  timeout       = 60

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "DOMAIN_API_KEY"       = module.domain_builder_api_key[0].secret
    "DOMAIN_REGISTRY_NAME" = local.domain_registry
    "JAVA_TOOL_OPTIONS"    = "-XX:MetaspaceSize=32m"
    "POSTGRES_DB_NAME"     = local.rds_dbuilder_db_identifier
    "POSTGRES_HOST"        = module.domain_builder_backend_db.rds_host
    "POSTGRES_PASSWORD"    = module.domain_builder_backend_db.master_password
    "POSTGRES_PORT"        = local.rds_dbuilder_port
    "POSTGRES_USERNAME"    = local.rds_dbuilder_user
    "PREVIEW_DB_NAME"      = local.domain_preview_database
    "PREVIEW_S3_LOCATION"  = "s3://${local.domain_preview_s3_bucket}"
    "PREVIEW_WORKGROUP"    = local.domain_preview_workgroup
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id, ]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR-407"
      dpr-resource-type  = "lambda"
      dpr-name           = local.lambda_dbuilder_name
    }
  )

  depends_on = [aws_iam_policy.s3_read_access_policy, aws_iam_policy.domain_builder_preview_policy, aws_iam_policy.domain_builder_publish_policy]
}

# Domain Builder RDS Instance
module "domain_builder_backend_db" {
  source = "./modules/rds/postgres"

  enable_rds         = local.enable_domain_builder_rds
  allocated_size     = local.rds_dbuilder_init_size
  max_allocated_size = local.rds_dbuilder_max_size
  subnets            = local.dpr_subnets
  vpc_id             = local.dpr_vpc
  kms                = local.rds_kms_arn
  name               = local.rds_dbuilder_name
  db_name            = local.rds_dbuilder_db_identifier
  db_instance_class  = local.rds_dbuilder_inst_class
  master_user        = local.rds_dbuilder_user
  storage_type       = local.rds_dbuilder_store_type
  parameter_group    = local.rds_dbuilder_parameter_group
  ca_cert_identifier = "rds-ca-rsa2048-g1" # Updated on 29th July 2024

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR-407"
      dpr-resource-type  = "lambda"
      dpr-name           = local.rds_dbuilder_name
    }
  )
}

# Ec2
module "domain_builder_cli_agent" {
  source = "./modules/compute_node"

  enable_compute_node         = local.enable_domain_builder_agent
  name                        = "${local.project}-domain-builder-agent-${local.env}"
  description                 = "Domain Builder CLI Agent"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.apigateway_get_policy}", ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "domain-builder"

  env_vars = {
    DOMAIN_API_KEY    = tostring(try(module.domain_builder_api_key[0].secret, null))
    REST_API_EXEC_ARN = tostring(try(module.domain_builder_api_gateway[0].rest_api_execution_arn, null))
    REST_API_ID       = tostring(try(module.domain_builder_api_gateway[0].rest_api_id, null))
    ENV               = local.env
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name           = "${local.project}-domain-builder-agent-${local.env}"
      dpr-resource-type  = "EC2 Instance"
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR2-XXXX"
    }
  )

  depends_on = [aws_iam_policy.apigateway_get, aws_iam_policy.kms_read_access_policy, aws_iam_policy.s3_read_access_policy]
}

# Domain Builder Flyway Lambda 
module "domain_builder_flyway_Lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda      = local.enable_dbuilder_flyway_lambda
  name               = local.flyway_dbuilder_name
  s3_bucket          = local.flyway_dbuilder_code_s3_bucket
  s3_key             = local.flyway_dbuilder_code_s3_key
  handler            = local.flyway_dbuilder_handler
  runtime            = local.flyway_dbuilder_runtime
  policies           = local.flyway_dbuilder_policies
  tracing            = local.flyway_dbuilder_tracing
  timeout            = 60
  lambda_trigger     = true
  trigger_bucket_arn = module.s3_artifacts_store.bucket_arn

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "DB_CONNECTION_STRING" = "jdbc:postgresql://${module.domain_builder_backend_db.rds_host}/${local.rds_dbuilder_db_identifier}"
    "DB_USERNAME"          = local.rds_dbuilder_user
    "DB_PASSWORD"          = module.domain_builder_backend_db.master_password
    "FLYWAY_METHOD"        = "migrate"
    "GIT_BRANCH"           = "main"
    "GIT_FOLDERS"          = "backend/src/main/resources/db/migration"
    "GIT_REPOSITORY"       = "https://github.com/ministryofjustice/digital-prison-reporting-domain-builder"
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id, ]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name           = local.flyway_dbuilder_name
      dpr-jira           = "DPR-584"
      dpr-resource-group = "domain-builder"
      dpr-resource-type  = "lambda"
    }
  )

}

# Deploy API GW VPC Link
module "domain_builder_gw_vpclink" {
  count = local.include_dbuilder_gw_vpclink == true ? 1 : 0

  source             = "./modules/vpc_endpoint"
  vpc_id             = local.dpr_vpc
  region             = local.account_region
  subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  security_group_ids = local.enable_dbuilder_serverless_gw ? [aws_security_group.gateway_endpoint_sg[0].id, ] : []

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR-583"
      dpr-resource-type  = "vpc_endpoint"
    }
  )
}

# Domain Builder API Gateway
module "domain_builder_api_gateway" {
  count = local.enable_dbuilder_serverless_gw == true ? 1 : 0

  source             = "./modules/apigateway/serverless-lambda-gw"
  enable_gateway     = local.enable_dbuilder_serverless_gw
  name               = local.serverless_gw_dbuilder_name
  lambda_arn         = module.domain_builder_backend_Lambda.lambda_invoke_arn
  lambda_name        = module.domain_builder_backend_Lambda.lambda_name
  subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  security_group_ids = local.enable_dbuilder_serverless_gw ? [aws_security_group.serverless_gw[0].id, ] : []
  endpoint_ids       = [data.aws_vpc_endpoint.api.id, ] # This Endpoint is managed and provisioned by MP Team, Dev "vpce-05d9421e74348aafb"

  tags = merge(
    local.all_tags,
    {
      dpr-name           = "${local.serverless_gw_dbuilder_name}-gw-${local.env}"
      dpr-resource-group = "domain-builder"
      dpr-jira           = "DPR-583"
      dpr-resource-type  = "apigateway"
    }
  )
}
