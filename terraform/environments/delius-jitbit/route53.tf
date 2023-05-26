locals {
  zone_name = "jitbit.cr.probation.service.justice.gov.uk"
}

# Needs to be created by ModernisationPlatform?
resource "aws_route53_zone" "public" {
  name     = local.zone_name
  tags     = local.tags
  provider = aws.core-network-services
}

resource "aws_acm_certificate" "external_test" {
  domain_name       = local.zone_name
  validation_method = "DNS"

  subject_alternative_names = ["helpdesk.${local.zone_name}", local.app_url]
  tags = merge(
    local.tags,
    {
      Environment = local.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_test" {
  provider = aws.core-network-services

  zone_id = aws_route53_zone.public.zone_id
  name    = local.app_url
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_test_validation" {
  provider = aws.core-network-services

  for_each = {
    for dvo in aws_acm_certificate.external_test.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.public.zone_id
}

resource "aws_acm_certificate_validation" "external_test" {
  certificate_arn         = aws_acm_certificate.external_test.arn
  validation_record_fqdns = [for record in aws_route53_record.external_test_validation : record.fqdn]
}
