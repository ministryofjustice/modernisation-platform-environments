locals {
  litellm_hostname = "claude-gateway.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
}

resource "aws_acm_certificate" "litellm" {
  domain_name       = local.litellm_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "litellm_cert_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in aws_acm_certificate.litellm.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "litellm" {
  certificate_arn         = aws_acm_certificate.litellm.arn
  validation_record_fqdns = [for record in aws_route53_record.litellm_cert_validation : record.fqdn]
}

resource "aws_route53_record" "litellm" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.litellm_hostname
  type    = "A"

  alias {
    name                   = aws_lb.litellm.dns_name
    zone_id                = aws_lb.litellm.zone_id
    evaluate_target_health = true
  }
}
