module "connected_vpc_outbound_route53_resolver_endpoint" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/route53/aws//modules/resolver-endpoint"
  version = "6.5.0"

  name      = "connected-vpc-outbound"
  vpc_id    = module.connected_vpc.vpc_id
  direction = "OUTBOUND"
  protocols = ["Do53"]

  ip_address = [
    {
      subnet_id = module.connected_vpc.private_subnets[0]
    },
    {
      subnet_id = module.connected_vpc.private_subnets[1]
    }
  ]

  security_group_ingress_rules = {
    connected_vpc = {
      cidr_ipv4 = module.connected_vpc.vpc_cidr_block
    }
  }

  security_group_egress_rules = {
    /* MoJO DNS Resolver Service */
    moj_service_resolver1 = {
      cidr_ipv4 = "10.180.80.5/32"
    }
    moj_service_resolver2 = {
      cidr_ipv4 = "10.180.81.5/32"
    }
  }

  tags = local.tags
}
