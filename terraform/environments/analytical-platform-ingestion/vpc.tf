module "connected_vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name            = "${local.application_name}-${local.environment}-connected"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = local.environment_configuration.connected_vpc_cidr
  private_subnets = local.environment_configuration.connected_vpc_private_subnets
  public_subnets  = local.environment_configuration.connected_vpc_public_subnets

  /* NAT gateway is temporary and will be retired when we're satisfied with DataSync end-to-end */
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

module "isolated_vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name            = "${local.application_name}-${local.environment}-isolated"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = local.environment_configuration.isolated_vpc_cidr
  public_subnets  = local.environment_configuration.isolated_vpc_public_subnets
  private_subnets = local.environment_configuration.isolated_vpc_private_subnets

  enable_nat_gateway     = local.environment_configuration.isolated_vpc_enable_nat_gateway
  one_nat_gateway_per_az = local.environment_configuration.isolated_vpc_one_nat_gateway_per_az

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

moved {
  from = module.vpc
  to   = module.isolated_vpc
}
