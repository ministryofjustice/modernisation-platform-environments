module "vpc_endpoints_security_group" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${module.vpc.name}-vpc-endpoints"
  description = "VPC endpoints security group"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_rules       = ["https-443-tcp"]

  tags = local.tags
}

module "vpc_vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_security_group.security_group_id]

  endpoints = {

    guardduty = {
      service             = "guardduty-data"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.eks_private[*].id
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-guardduty", module.vpc.name) }
      )
    },
  }

}