module "isolated_vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.13.0"

  vpc_id             = module.isolated_vpc.vpc_id
  subnet_ids         = module.isolated_vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-logs-vpc-endpoint", local.application_name) }
      )
    },
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sts-vpc-endpoint", local.application_name) }
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
        { Name = format("%s-s3-vpc-endpoint", local.application_name) }
      )
    },
    secretsmanager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-secretsmanager-vpc-endpoint", local.application_name) }
      )
    },
  }
}

moved {
  from = module.vpc_endpoints
  to   = module.isolated_vpc_endpoints
}
