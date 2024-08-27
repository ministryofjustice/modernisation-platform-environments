resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = "ldap.${var.env_name}.${var.account_config.dns_suffix}"
  type    = "CNAME"
  ttl     = "60"
  records = [module.nlb.dns_name]
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = var.account_config.route53_network_services_zone.zone_id
}

resource "aws_acm_certificate" "external" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = [aws_route53_record.external.name]
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = var.account_config.route53_external_zone.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
