data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc_isolated" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.1"

  name            = "${local.application_name}-${local.environment}-isolated"
  azs             = local.vpc_availability_zones
  cidr            = local.vpc_cidr
  public_subnets  = local.vpc_subnets_public
  private_subnets = local.vpc_subnets_private

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  flow_log_cloudwatch_log_group_retention_in_days = local.cloudwatch_retention_days
  flow_log_max_aggregation_interval               = 60

  tags = local.tags
}
