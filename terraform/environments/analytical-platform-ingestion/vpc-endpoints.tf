module "connected_vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id     = module.connected_vpc.vpc_id
  subnet_ids = module.connected_vpc.private_subnets

  endpoints = {
    datasync = {
      service             = "datasync"
      service_type        = "Interface"
      private_dns_enabled = true
      security_group_ids = [
        module.datasync_vpc_endpoint_security_group.security_group_id,
        module.datasync_task_eni_security_group.security_group_id
      ]
      tags = merge(
        local.tags,
        { Name = format("%s-datasync", "${local.application_name}-${local.environment}-connected") }
      )
    },
    /*  These VPC endpoints (ssm, ssmmessages and ec2messages) are temporary and will be retired when we're satisfied with DataSync end-to-end */
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.connected_vpc_endpoints.id]
      tags = merge(
        local.tags,
        { Name = format("%s-ssm", "${local.application_name}-${local.environment}-connected") }
      )
    },
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.connected_vpc_endpoints.id]
      tags = merge(
        local.tags,
        { Name = format("%s-ssmmessages", "${local.application_name}-${local.environment}-connected") }
      )
    },
    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.connected_vpc_endpoints.id]
      tags = merge(
        local.tags,
        { Name = format("%s-ec2messages", "${local.application_name}-${local.environment}-connected") }
      )
    }
  }
}

module "isolated_vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id             = module.isolated_vpc.vpc_id
  subnet_ids         = module.isolated_vpc.private_subnets
  security_group_ids = [aws_security_group.isolated_vpc_endpoints.id]

  endpoints = {
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-logs", "${local.application_name}-${local.environment}-isolated") }
      )
    },
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sts", "${local.application_name}-${local.environment}-isolated") }
      )
    },
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.isolated_vpc.default_route_table_id,
        module.isolated_vpc.private_route_table_ids,
        module.isolated_vpc.public_route_table_ids
      ])
      tags = merge(
        local.tags,
        { Name = format("%s-s3", "${local.application_name}-${local.environment}-isolated") }
      )
    },
    secretsmanager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-secretsmanager", "${local.application_name}-${local.environment}-isolated") }
      )
    },
  }
}

moved {
  from = module.vpc_endpoints
  to   = module.isolated_vpc_endpoints
}
