module "isolated_vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name            = "${local.application_name}-${local.environment}-isolated"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = local.vpc_configuration.isolated_vpc_cidr
  public_subnets  = local.vpc_configuration.isolated_vpc_public_subnet_cidrs
  private_subnets = local.vpc_configuration.isolated_vpc_private_subnet_cidrs

  enable_nat_gateway     = local.vpc_configuration.isolated_vpc_enable_nat_gateway
  one_nat_gateway_per_az = local.vpc_configuration.isolated_vpc_one_nat_gateway_per_az

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}
