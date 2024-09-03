#trivy:ignore:AVD-AWS-0102
#trivy:ignore:AVD-AWS-0105
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
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssm-vpc-endpoint", local.application_name) }
      )
    },
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssmmessages-vpc-endpoint", local.application_name) }
      )
    },
    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
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

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${local.application_name}-${local.environment}-igw"
  }
}

# Add a route for outbound traffic to reach the internet gateway
resource "aws_route" "internet_access" {
  route_table_id         = module.vpc.private_route_table_ids.0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
