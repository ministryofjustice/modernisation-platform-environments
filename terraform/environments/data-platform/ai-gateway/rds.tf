module "ai_gateway_rds" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=bc8c1e240a98fd54a12c61c70de91cbabec71863" # v7.2.0

  identifier = local.component_name

  engine         = "postgres"
  engine_version = local.environment_configuration.rds_engine_version
  family         = "postgres${split(".", local.environment_configuration.rds_engine_version)[0]}"
  instance_class = local.environment_configuration.rds_instance_class

  allocated_storage     = local.environment_configuration.rds_allocated_storage
  max_allocated_storage = local.environment_configuration.rds_allocated_storage * 2
  storage_encrypted     = true
  kms_key_id            = data.aws_kms_key.rds_shared.arn

  db_name                     = "litellm"
  username                    = "litellm"
  manage_master_user_password = false
  password_wo                 = random_password.rds.result
  password_wo_version         = 1

  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.shared-data.ids
  vpc_security_group_ids = [module.ai_gateway_rds_security_group.security_group_id]

  multi_az            = local.is-production
  skip_final_snapshot = !local.is-production
  deletion_protection = local.is-production

  backup_retention_period = local.is-production ? 7 : 1

  create_db_option_group    = false
  create_db_parameter_group = true

  tags = local.tags
}

module "ai_gateway_rds_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/rds"

  secret_string = jsonencode({
    username = module.ai_gateway_rds.db_instance_username
    password = random_password.rds.result
    host     = module.ai_gateway_rds.db_instance_address
    port     = tostring(module.ai_gateway_rds.db_instance_port)
    dbname   = module.ai_gateway_rds.db_instance_name
  })
}

module "ai_gateway_rds_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa" # v5.3.1

  name            = "${local.component_name}-rds"
  description     = "Security group for LiteLLM RDS PostgreSQL"
  vpc_id          = data.aws_vpc.shared.id
  use_name_prefix = false

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      description              = "Allow PostgreSQL access from EKS cluster"
      source_security_group_id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  tags = local.tags
}
