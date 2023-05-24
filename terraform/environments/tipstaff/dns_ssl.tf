resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.is-production ? "${var.networking[0].application}.${local.application_data.accounts[local.environment].domain_name}" : "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.${local.application_data.accounts[local.environment].domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff_lb.dns_name
    zone_id                = aws_lb.tipstaff_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = local.is-production ? "${var.networking[0].application}.${local.application_data.accounts[local.environment].domain_name}" : local.application_data.accounts[local.environment].domain_name
  validation_method = "DNS"

  subject_alternative_names = local.is-production ? ["${var.networking[0].application}.${local.application_data.accounts[local.environment].domain_name}"] : ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.${local.application_data.accounts[local.environment].domain_name}"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
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
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
