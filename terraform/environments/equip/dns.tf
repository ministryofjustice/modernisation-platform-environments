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

resource "aws_acm_certificate" "lb_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "${local.application_data.accounts[local.environment].public_dns_name_web}",
  ]

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "waf_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.lb_cert.arn
  validation_record_fqdns = [for record in local.domain_types : record.name]
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = length(local.domain_name_sub)
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[count.index]
  records         = [local.domain_record_sub[count.index]]
  ttl             = 60
  type            = local.domain_type_sub[count.index]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_route53_resolver_endpoint" "equip-domain" {
  provider = aws.core-vpc

  name      = "equip-local"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.aws_dns_resolver.id
  ]

  ip_address {
    subnet_id = data.aws_subnet.private_subnets_a.id
  }

  ip_address {
    subnet_id = data.aws_subnet.private_subnets_b.id
  }

  ip_address {
    subnet_id = data.aws_subnet.private_subnets_c.id
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
