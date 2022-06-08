resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.citrix_alb.dns_name
    zone_id                = aws_lb.citrix_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_resolver_endpoint" "equip-domain" {
  provider = aws.core-vpc

  name      = "equip-local"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.aws_dns_resolver.id
  ]

  ip_address {
    subnet_id = data.aws_subnet.private_subnet_a.id
  }

  ip_address {
    subnet_id = data.aws_subnet.private_subnet_b.id
  }

  ip_address {
    subnet_id = data.aws_subnet.private_subnet_c.id
  }

  tags = {
    Name = "equip-local-${local.application_name}-${local.environment}"
  }
}

resource "aws_route53_resolver_rule" "fwd" {
  provider = aws.core-vpc

  domain_name          = "equip.local"
  name                 = "equip-local"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.equip-domain.id

  target_ip {
    ip = module.win2016_multiple["COR-A-DC01"].private_ip[0]
  }

  target_ip {
    ip = module.win2016_multiple["COR-A-DC02"].private_ip[0]
  }
}

resource "aws_route53_resolver_rule_association" "equip-domain" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id           = data.aws_vpc.shared.id
}
