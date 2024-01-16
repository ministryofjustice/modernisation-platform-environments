module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

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

module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  security_group_ids = []
  vpc_id             = module.vpc.vpc_id

  endpoints = {
    logs = {
      security_group_ids = [aws_security_group.vpc-endpoints.id]
      service            = "logs"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      tags = merge(
        local.tags,
        { Name = format("%s-logs-api-vpc-endpoint", local.application_name) }
      )
    },
    sagemaker-api = {
      security_group_ids = [aws_security_group.vpc-endpoints.id]
      service            = "sagemaker.api"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      tags = merge(
        local.tags,
        { Name = format("%s-sagemaker-api-vpc-endpoint", local.application_name) }
      )
    },
    sagemaker-runtime = {
      security_group_ids = [aws_security_group.vpc-endpoints.id]
      service            = "sagemaker.runtime"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      tags = merge(
        local.tags,
        { Name = format("%s-sagemaker-runtime-vpc-endpoint", local.application_name) }
      )
    },
    sagemaker-catalog = {
      security_group_ids = [aws_security_group.vpc-endpoints.id]
      service            = "servicecatalog"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      tags = merge(
        local.tags,
        { Name = format("%s-servicecatalog-vpc-endpoint", local.application_name) }
      )
    },
    sts = {
      security_group_ids = [aws_security_group.vpc-endpoints.id]
      service            = "sts"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
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

resource "aws_security_group" "vpc-endpoints" {
  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "allow-vpc-in" {
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  description       = "Allow all traffic in from VPC CIDR"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.vpc-endpoints.id
  to_port           = 65535
  type              = "ingress"
}