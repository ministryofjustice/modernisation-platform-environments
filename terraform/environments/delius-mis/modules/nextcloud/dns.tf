resource "aws_route53_record" "nextcloud_external" {
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = "nextcloud.${var.account_config.dns_suffix}"
  type    = "A"

  alias {
    name                   = aws_alb.nextcloud.dns_name
    zone_id                = aws_alb.nextcloud.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "nextcloud_external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    aws_route53_record.nextcloud_external.name
  ]
  tags = var.tags

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
  zone_id         = var.account_config.route53_external_zone.zone_id
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


resource "aws_acm_certificate_validation" "nextcloud_external" {
  certificate_arn         = aws_acm_certificate.nextcloud_external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
