module "ai_gateway_aurora" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds-aurora.git?ref=2c3946c8191278ad974bbb077da5e03986e24f4d" # v10.2.0

  name                   = local.component_name
  engine                 = "aurora-postgresql"
  engine_version         = local.environment_configuration.aurora_engine_version
  cluster_instance_class = local.environment_configuration.aurora_instance_class
  instances              = local.environment_configuration.aurora_instances

  serverlessv2_scaling_configuration = local.environment_configuration.aurora_serverlessv2_scaling_configuration

  database_name               = "litellm"
  master_username             = "litellm"
  manage_master_user_password = false
  master_password_wo          = random_password.aurora.result
  master_password_wo_version  = 1

  storage_encrypted = true
  kms_key_id        = module.ai_gateway_aurora_kms_key.key_arn

  create_db_subnet_group = true
  subnets                = data.aws_subnets.eks-data.ids
  vpc_id                 = data.aws_vpc.eks.id

  security_group_ingress_rules = {
    eks_ingress = {
      cidr_ipv4   = data.aws_vpc.eks.cidr_block
      description = "Allow PostgreSQL access from EKS pods"
    }
  }

  skip_final_snapshot = !local.is-production
  deletion_protection = local.is-production

  backup_retention_period = local.is-production ? 7 : 1

  create_cloudwatch_log_group     = true
  enabled_cloudwatch_logs_exports = ["postgresql"]

  cluster_monitoring_interval = local.is-production ? 60 : 0
  create_monitoring_role      = local.is-production
  iam_role_name               = "${local.component_name}-monitoring"
  iam_role_use_name_prefix    = true
}

module "ai_gateway_aurora_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/aurora"

  secret_string = jsonencode(merge(
    {
      username = module.ai_gateway_aurora.cluster_master_username
      password = random_password.aurora.result
      host     = module.ai_gateway_aurora.cluster_endpoint
      port     = tostring(module.ai_gateway_aurora.cluster_port)
      dbname   = module.ai_gateway_aurora.cluster_database_name
    },
    local.has_reader ? {
      read-url = "postgresql://${module.ai_gateway_aurora.cluster_master_username}:${random_password.aurora.result}@${module.ai_gateway_aurora.cluster_reader_endpoint}/${module.ai_gateway_aurora.cluster_database_name}"
    } : {}
  ))
}
