module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # v5.8.1

  name            = "${local.application_name}-${local.environment}"
  azs             = local.availability_zones
  cidr            = local.application_data.accounts[local.environment].vpc_cidr
  private_subnets = concat(
    values(aws_subnet.vSRX01_subnets)[*].cidr_block,
    values(aws_subnet.vSRX02_subnets)[*].cidr_block
  )
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
  subnet_ids         = concat(
    values(aws_subnet.vSRX01_subnets)[*].id,
    values(aws_subnet.vSRX02_subnets)[*].id
  )
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



resource "aws_subnet" "vSRX01_subnets" {
  for_each = {
    "vSRX01 Management Range"    = "10.100.105.0/24"
    "vSRX01 PSK External Range"  = "10.100.110.0/24"
    "vSRX01 Cert External Range" = "10.100.115.0/24"
    "vSRX01 Internal Range"      = "10.100.120.0/24"
    "Juniper Management & KMS Server Range" = "10.100.50.0/24"
  }

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = local.tags
}

resource "aws_subnet" "vSRX02_subnets" {
  for_each = {
    "vSRX02 Management Range"    = "10.100.205.0/24"
    "vSRX02 PSK External Range"  = "10.100.210.0/24"
    "vSRX02 Cert External Range" = "10.100.215.0/24"
    "vSRX02 Internal Range"      = "10.100.220.0/24"
  }

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = local.tags
}