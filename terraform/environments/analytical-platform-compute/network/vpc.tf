#tfsec:ignore:avd-aws-0102 NACLs not restricted
#tfsec:ignore:avd-aws-0105 NACLs not restricted
module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name                = local.our_vpc_name
  azs                 = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr                = local.environment_configuration.vpc_cidr
  public_subnets      = local.environment_configuration.vpc_public_subnets
  database_subnets    = local.environment_configuration.vpc_database_subnets
  elasticache_subnets = local.environment_configuration.vpc_elasticache_subnets
  intra_subnets       = local.environment_configuration.vpc_intra_subnets
  private_subnets     = local.environment_configuration.vpc_private_subnets

  enable_nat_gateway     = local.environment_configuration.vpc_enable_nat_gateway
  one_nat_gateway_per_az = local.environment_configuration.vpc_one_nat_gateway_per_az
  single_nat_gateway     = local.environment_configuration.vpc_single_nat_gateway

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_name_prefix       = local.vpc_flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_name_suffix       = local.vpc_flow_log_cloudwatch_log_group_name_suffix
  flow_log_cloudwatch_log_group_kms_key_id        = module.vpc_flow_logs_kms.key_arn
  flow_log_cloudwatch_log_group_retention_in_days = local.vpc_flow_log_cloudwatch_log_group_retention_in_days
  flow_log_max_aggregation_interval               = local.vpc_flow_log_max_aggregation_interval
  vpc_flow_log_tags                               = { Name = local.our_vpc_name }
  flow_log_log_format                             = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.eks_cluster_name
  }

  tags = local.tags
}
