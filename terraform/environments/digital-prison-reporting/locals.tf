#### This file can be used to store locals specific to the member account ####
#### DPR Specific ####
locals {
  project = local.application_data.accounts[local.environment].project_short_id
  # glue_db                       = local.application_data.accounts[local.environment].glue_db_name
  # glue_db_data_domain           = local.application_data.accounts[local.environment].glue_db_data_domain
  description              = local.application_data.accounts[local.environment].db_description
  create_db                = local.application_data.accounts[local.environment].create_database
  glue_job                 = local.application_data.accounts[local.environment].glue_job_name
  create_job               = local.application_data.accounts[local.environment].create_job
  create_sec_conf          = local.application_data.accounts[local.environment].create_security_conf
  env                      = local.environment
  s3_kms_arn               = aws_kms_key.s3.arn
  kinesis_kms_arn          = aws_kms_key.kinesis-kms-key.arn
  kinesis_kms_id           = data.aws_kms_key.kinesis_kms_key.key_id
  create_bucket            = local.application_data.accounts[local.environment].setup_buckets
  account_id               = data.aws_caller_identity.current.account_id
  account_region           = data.aws_region.current.name
  create_kinesis           = local.application_data.accounts[local.environment].create_kinesis_streams
  enable_glue_registry     = local.application_data.accounts[local.environment].create_glue_registries
  setup_buckets            = local.application_data.accounts[local.environment].setup_s3_buckets
  create_glue_connection   = local.application_data.accounts[local.environment].create_glue_connections
  image_id                 = local.application_data.accounts[local.environment].ami_image_id
  instance_type            = local.application_data.accounts[local.environment].ec2_instance_type
  create_datamart          = local.application_data.accounts[local.environment].setup_redshift
  redshift_cluster_name    = "${local.application_data.accounts[local.environment].project_short_id}-redshift-${local.environment}"
  kinesis_stream_ingestor  = "${local.application_data.accounts[local.environment].project_short_id}-kinesis-ingestor-${local.environment}"
  kinesis_endpoint         = "https://kinesis.eu-west-2.amazonaws.com"
  cloud_platform_cidr      = "172.20.0.0/16"
  enable_dpr_cloudtrail    = local.application_data.accounts[local.environment].enable_cloud_trail
  generic_lambda           = "${local.project}-generic-lambda"
  enable_generic_lambda_sg = true # True for all Envs, Common SG Group
  enable_replication_task  = local.application_data.accounts[local.environment].enable_dms_replication_task

  # Domain Builder, Variables
  dpr_vpc                        = data.aws_vpc.shared.id
  dpr_subnets                    = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  rds_kms_arn                    = aws_kms_key.rds.arn
  enable_domain_builder_rds      = local.application_data.accounts[local.environment].enable_domain_builder_rds
  rds_dbuilder_name              = "${local.project}-backend-rds"
  rds_dbuilder_db_identifier     = "${local.project}_domain_builder"
  rds_dbuilder_inst_class        = "db.t3.small"
  rds_dbuilder_store_type        = "gp2"
  rds_dbuilder_init_size         = 10
  rds_dbuilder_max_size          = 50
  rds_dbuilder_parameter_group   = "postgres14"
  rds_dbuilder_port              = 5432
  rds_dbuilder_user              = "domain_builder"
  enable_dbuilder_lambda         = local.application_data.accounts[local.environment].enable_domain_builder_lambda
  lambda_dbuilder_name           = "${local.project}-domain-builder-backend-api"
  lambda_dbuilder_runtime        = "java11"
  lambda_dbuilder_tracing        = "Active"
  lambda_dbuilder_handler        = "io.micronaut.function.aws.proxy.MicronautLambdaHandler"
  lambda_dbuilder_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_dbuilder_code_s3_key    = "build-artifacts/domain-builder/jars/domain-builder-backend-api-vLatest-all.jar"
  lambda_dbuilder_policies       = [aws_iam_policy.s3_read_access_policy.arn, ]
  enable_domain_builder_agent    = local.application_data.accounts[local.environment].enable_domain_builder_agent
  enable_dbuilder_flyway_lambda  = local.application_data.accounts[local.environment].enable_dbuilder_flyway_lambda
  flyway_dbuilder_name           = "${local.project}-domain-builder-flyway"
  flyway_dbuilder_code_s3_bucket = module.s3_artifacts_store.bucket_id
  flyway_dbuilder_code_s3_key    = "third-party/flyway-generic/flyway-lambda-0.9.jar"
  flyway_dbuilder_handler        = "com.geekoosh.flyway.FlywayHandler"
  flyway_dbuilder_runtime        = "java11"
  flyway_dbuilder_policies       = [aws_iam_policy.s3_read_access_policy.arn, data.aws_iam_policy.rds_full_access.arn, ]
  flyway_dbuilder_tracing        = "Active"
  enable_dbuilder_serverless_gw  = local.application_data.accounts[local.environment].enable_dbuilder_serverless_gw
  include_dbuilder_gw_vpclink    = local.application_data.accounts[local.environment].include_dbuilder_gw_vpclink
  serverless_gw_dbuilder_name    = "${local.project}-serverless-lambda"

  nomis_secrets_placeholder = {
    db_name  = "nomis"
    password = "placeholder"
    user     = "placeholder"
    endpoint = "0.0.0.0"
    port     = "1521"
  }

  # Evaluate Redshift Secrets and Populate
  redshift_secrets = {
    dbClusterIdentifier = "dpr-redshift-${local.project}"
    engine              = "redshift"
    host                = module.datamart.cluster_endpoint
    password            = module.datamart.redshift_master_password
    port                = "5439"
    username            = module.datamart.redshift_master_user
  }

  all_tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )
}