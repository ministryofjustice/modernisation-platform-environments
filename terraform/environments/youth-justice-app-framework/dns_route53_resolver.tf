module "route53_endpoint_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = "4.13.0"
  
    vpc_id      = data.aws_vpc.shared.id
    name        = "Route53 to Local DNS"
    description = "Control access from Route 53 to the Directory Service."
  
    egress_with_source_security_group_id = [{
      description              = "Route53 to Local DNS TCP"
      rule                     = "dns-tcp"
      source_security_group_id = module.ds.directory_service_sg_id
    },
    {
      description              = "Route53 to Local DNS UDP"
      rule                     = "dns-udp"
      source_security_group_id = module.ds.directory_service_sg_id
    }]
  
}


resource "aws_route53_resolver_endpoint" "vpc" {
  provider = aws.core-vpc

  name                   = "local"
  direction              = "OUTBOUND"
  resolver_endpoint_type = "IPV4"

  security_group_ids = [ module.route53_endpoint_sg.security_group_id ]

  ip_address { subnet_id = data.aws_subnet.private_subnets_a.id }
  ip_address { subnet_id = data.aws_subnet.private_subnets_b.id}
  ip_address { subnet_id = data.aws_subnet.private_subnets_c.id }

  protocols = ["Do53"]
}

locals {
  dns_ip_addresses = tolist(module.ds.dns_ip_addresses)
  ip_address_count = length(module.ds.dns_ip_addresses)
}
  

resource "aws_route53_resolver_rule" "i2n" {
  provider = aws.core-vpc

  domain_name          = "i2n.com"
  name                 = "directory"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.vpc.id

  target_ip { ip = local.dns_ip_addresses[0] }
  target_ip { ip = local.dns_ip_addresses[1] }
  target_ip { ip = local.ip_address_count > 2 ? local.dns_ip_addresses[2] : null}
}

resource "aws_route53_resolver_rule_association" "i2n" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.i2n.id
  vpc_id           = data.aws_vpc.shared.id
}