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

# module "vpc_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "~> 5.0"

#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   subnet_ids         = module.vpc.private_subnets
#   vpc_id             = module.vpc.vpc_id

#   endpoints = {
#     logs = {
#       service      = "logs"
#       service_type = "Interface"
#       tags = merge(
#         local.tags,
#         { Name = format("%s-logs-api-vpc-endpoint", local.application_name) }
#       )
#     },
#     sts = {
#       service      = "sts"
#       service_type = "Interface"
#       tags = merge(
#         local.tags,
#         { Name = format("%s-sts-vpc-endpoint", local.application_name) }
#       )
#     },
#     s3 = {
#       service         = "s3"
#       service_type    = "Gateway"
#       route_table_ids = module.vpc.private_route_table_ids
#       tags = merge(
#         local.tags,
#         { Name = format("%s-s3-vpc-endpoint", local.application_name) }
#       )
#     }
#   }
# }

# resource "aws_security_group" "vpc_endpoints" {
#   description = "Security Group for controlling all VPC endpoint traffic"
#   name        = format("%s-vpc-endpoint-sg", local.application_name)
#   vpc_id      = module.vpc.vpc_id
#   tags        = local.tags
# }

# resource "aws_security_group_rule" "allow_all_vpc" {
#   cidr_blocks       = [module.vpc.vpc_cidr_block]
#   description       = "Allow all traffic in from VPC CIDR"
#   from_port         = 0
#   protocol          = -1
#   security_group_id = aws_security_group.vpc_endpoints.id
#   to_port           = 65535
#   type              = "ingress"
# }
