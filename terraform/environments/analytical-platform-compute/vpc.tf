module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                = "${local.application_name}-${local.environment}"
  azs                 = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr                = local.environment_configuration.vpc_cidr
  database_subnets    = local.environment_configuration.vpc_database_subnets
  elasticache_subnets = local.environment_configuration.vpc_elasticache_subnets
  intra_subnets       = local.environment_configuration.vpc_intra_subnets
  private_subnets     = local.environment_configuration.vpc_private_subnets
  public_subnets      = local.environment_configuration.vpc_public_subnets

  enable_nat_gateway     = local.environment_configuration.vpc_enable_nat_gateway
  one_nat_gateway_per_az = local.environment_configuration.vpc_one_nat_gateway_per_az
  single_nat_gateway     = local.environment_configuration.vpc_single_nat_gateway

  enable_flow_log                   = true
  flow_log_destination_type         = "cloud-watch-logs"
  flow_log_destination_arn          = module.vpc_flow_logs_log_group.cloudwatch_log_group_arn
  flow_log_cloudwatch_iam_role_arn  = module.vpc_flow_logs_iam_role.iam_role_arn
  flow_log_max_aggregation_interval = local.vpc_flow_log_max_aggregation_interval

  tags = local.tags
}
