module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpc_endpoints_security_group.security_group_id]

  endpoints = {
    /* Interfaces */
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sts", module.vpc.name) }
      )
    },
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-logs", module.vpc.name) }
      )
    },
    kms = {
      service             = "kms"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-kms", module.vpc.name) }
      )
    },
    eks = {
      service             = "eks"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-eks", module.vpc.name) }
      )
    },
    eks-auth = {
      service             = "eks-auth"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-eks-auth", module.vpc.name) }
      )
    },
    guardduty-data = {
      service             = "guardduty-data"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-guardduty-data", module.vpc.name) }
      )
    },
    rds = {
      service             = "rds"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-rds", module.vpc.name) }
      )
    },
    rds-data = {
      service             = "rds-data"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-rds-data", module.vpc.name) }
      )
    },
    elasticache = {
      service             = "elasticache"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-elasticache", module.vpc.name) }
      )
    },
    secretsmanager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-secretsmanager", module.vpc.name) }
      )
    },
    aps = {
      service             = "aps"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-aps", module.vpc.name) }
      )
    },
    aps-workspaces = {
      service             = "aps-workspaces"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-aps-workspaces", module.vpc.name) }
      )
    },
    /* Gateways */
    /*
      Removing the S3 VPC endpoint while we investigate how APC Airflow workloads can do cross-region actions.
      Destination buckets are in eu-west-1.
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
        { Name = format("%s-s3", module.vpc.name) }
      )
    }
    */
  }

  tags = local.tags
}
