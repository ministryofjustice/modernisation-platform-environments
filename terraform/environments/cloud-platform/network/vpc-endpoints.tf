module "vpc_endpoints_security_group" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${module.vpc.name}-vpc-endpoints"
  description = "VPC endpoints security group"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_rules       = ["https-443-tcp"]

  # Additional ports for SES SMTP VPC endpoint
  ingress_with_cidr_blocks = [
    {
      from_port   = 465
      to_port     = 465
      protocol    = "tcp"
      description = "SES SMTP - SMTPS"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 587
      to_port     = 587
      protocol    = "tcp"
      description = "SES SMTP - SMTP submission"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 2465
      to_port     = 2465
      protocol    = "tcp"
      description = "SES SMTP - SMTPS alternate"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 2587
      to_port     = 2587
      protocol    = "tcp"
      description = "SES SMTP - SMTP submission alternate"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  tags = local.tags
}

module "vpc_vpc-endpoints" {
  source   = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version  = "6.5.1"
  for_each = toset(local.vpc_interface_endpoint_service_names)

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_security_group.security_group_id]

  endpoints = {
    (each.value) = {
      service             = each.value
      service_type        = "Interface"
      subnet_ids          = aws_subnet.eks_private[*].id
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-%s", module.vpc.name, each.value) }
      )
    }
  }
}

module "vpc-gateway-endpoints" {
  source   = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version  = "6.5.1"
  for_each = toset(local.vpc_gateway_endpoint_service_names)

  vpc_id = module.vpc.vpc_id

  endpoints = {
    (each.value) = {
      service         = each.value
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = merge(
        local.tags,
        { Name = "${module.vpc.name}-${each.value}" }
      )
    }
  }
}