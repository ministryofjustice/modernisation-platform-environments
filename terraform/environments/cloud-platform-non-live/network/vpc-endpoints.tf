module "vpc_vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id = module.vpc.vpc_id

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