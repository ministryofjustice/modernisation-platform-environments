module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.8.1"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpc_endpoints_security_group.security_group_id]

  endpoints = {
    sts = {
      service      = "sts"
      service_type = "Interface"
      tags = merge(
        local.tags,
        { Name = format("%s-sts", module.vpc.name) }
      )
    },
    logs = {
      service      = "logs"
      service_type = "Interface"
      tags = merge(
        local.tags,
        { Name = format("%s-logs", module.vpc.name) }
      )
    },
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.default_route_table_id,
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      ])
      tags = merge(
        local.tags,
        { Name = format("%s-s3", local.application_name) }
      )
    },
  }
}
