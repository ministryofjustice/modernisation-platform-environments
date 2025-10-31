
/*
## Import Statements that were used to deal with issues arising following the last Development Service Destroy. They may not be needed in future.
import {
  to = aws_route53_resolver_rule.i2n
  id = "rslvr-rr-534317bb27d044dda"
}

import {
  to = aws_route53_resolver_rule_association.i2n
  id = "rslvr-rrassoc-615763f9e2c242519"
}
*/

## AWS Resolver Endpoint security group
resource "aws_security_group" "aws_dns_resolver" {
  provider    = aws.core-vpc
  name        = "${local.project_name}-${local.environment}-dns-resolver"
  description = "Security Group for DNS resolver request"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

locals {
  dns_endpoint_rules = {
    "TCP_53" : {
      "from_port" : 53,
      "to_port" : 53,
      "protocol" : "TCP"
    },
    "UDP_53" : {
      "from_port" : 53,
      "to_port" : 53,
      "protocol" : "UDP"
    }
  }
}

resource "aws_security_group_rule" "ingress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.dns_endpoint_rules
  description       = format("VPC to DNS Endpoint traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.dns_endpoint_rules
  description       = format("DNS Endpoint to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_route53_resolver_endpoint" "vpc" {
  provider = aws.core-vpc

  name                   = "${local.project_name}-${local.environment}-local"
  direction              = "OUTBOUND"
  resolver_endpoint_type = "IPV4"

  security_group_ids = [aws_security_group.aws_dns_resolver.id]

  ip_address { subnet_id = data.aws_subnet.private_subnets_a.id }
  ip_address { subnet_id = data.aws_subnet.private_subnets_b.id }
  ip_address { subnet_id = data.aws_subnet.private_subnets_c.id }

  protocols = ["Do53"]

  tags = local.tags
}

locals {
  dns_ip_addresses = tolist(module.ds.dns_ip_addresses)
  ip_address_count = length(module.ds.dns_ip_addresses)
}


resource "aws_route53_resolver_rule" "i2n" {
  provider = aws.core-vpc

  domain_name          = "i2n.com"
  name                 = "${local.project_name}-${local.environment}-directory"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.vpc.id

  dynamic "target_ip" {
    for_each = local.dns_ip_addresses
    content {
      ip = target_ip.value
    }

  }
  #  target_ip { ip = local.dns_ip_addresses[0] }
  #  target_ip { ip = local.dns_ip_addresses[1] }
  #  target_ip { ip = local.ip_address_count > 2 ? local.dns_ip_addresses[2] : null}

  tags = local.tags
}

resource "aws_route53_resolver_rule_association" "i2n" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.i2n.id
  vpc_id           = data.aws_vpc.shared.id
  name             = "${local.project_name}-${local.environment}-association"
}