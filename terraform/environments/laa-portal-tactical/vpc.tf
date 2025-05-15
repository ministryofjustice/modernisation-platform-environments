module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # v5.8.1

  name            = "${local.application_name}-${local.environment}"
  azs             = local.availability_zones
  cidr            = local.application_data.accounts[local.environment].vpc_cidr
  private_subnets = local.private_subnets
  public_subnets = local.public_subnets
  database_subnets = local.database_subnets

  enable_nat_gateway = true # Disable for now

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # v5.8.1

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
    },
    ssm = {
      service         = "ssm"
      service_type    = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssm-vpc-endpoint", local.application_name) }
      )
    },
    ssmmessages = {
      service         = "ssmmessages"
      service_type    = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssmmessages-vpc-endpoint", local.application_name) }
      )
    },
    ec2messages = {
      service         = "ec2messages"
      service_type    = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ec2messages-vpc-endpoint", local.application_name) }
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

# VPC peering
resource "aws_ssm_parameter" "mp_shared_vpc_id" {
  #checkov:skip=CKV_AWS_337: Standard key is fine here
  name = "mp_shared_vpc_id"
  type = "SecureString"
  value = "DEFAULT"
  tags = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_vpc_peering_connection" "laa_mp_vpc" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = aws_ssm_parameter.mp_shared_vpc_id.value
  peer_owner_id = local.environment_management.account_ids[local.provider_name]
  tags = merge(
    local.tags,
    {Side = "Requester"}
  )
}