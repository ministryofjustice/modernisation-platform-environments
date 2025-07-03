#trivy:ignore:AVD-AWS-0102
module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # v5.8.1

  name            = "${local.application_name}-${local.environment}"
  azs             = local.availability_zones
  cidr            = local.application_data.accounts[local.environment].vpc_cidr
  private_subnets = local.private_subnets

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v6.0.1"

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id

  endpoints = {
    logs = {
      service      = "logs"
      service_type = "Interface"
      tags = merge(
        local.tags,
        { Name = format("%s-logs-api-vpc-endpoint", local.application_name) }
      )
    },
    sts = {
      service      = "sts"
      service_type = "Interface"
      tags = merge(
        local.tags,
        { Name = format("%s-sts-vpc-endpoint", local.application_name) }
      )
    },
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = merge(
        local.tags,
        { Name = format("%s-s3-vpc-endpoint", local.application_name) }
      )
    }
  }
}

resource "aws_security_group" "vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "allow_all_vpc" {
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  description       = "Allow all traffic in from VPC CIDR"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.vpc_endpoints.id
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group" "transfer_server" {
  description = "Security Group for Transfer Server"
  name        = "transfer-server"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}


module "isolated_vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

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
