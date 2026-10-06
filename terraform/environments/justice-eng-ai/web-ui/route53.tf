# Hosted zone delegated from the modernisation-platform account via NS
# records raised in a companion PR there (ai-builder-dev./ai-builder. under
# modernisation-platform.service.justice.gov.uk). After applying here, copy
# aws_route53_zone.app's name servers (see the route53_zone_name_servers
# output below) into that PR's REPLACE_WITH_*_NAME_SERVER_* placeholders.
locals {
  hosted_zone_name = local.is-production ? "ai-builder.modernisation-platform.service.justice.gov.uk" : "ai-builder-dev.modernisation-platform.service.justice.gov.uk"
}

resource "aws_route53_zone" "app" {
  name = local.hosted_zone_name
  tags = local.tags
}

output "route53_zone_name_servers" {
  value       = aws_route53_zone.app.name_servers
  description = "Paste into the modernisation-platform repo's NS delegation record for this environment."
}

resource "aws_acm_certificate" "site_eu_west_2" {
  domain_name               = local.builder_hostname
  subject_alternative_names = [local.forge_hostname]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "site_eu_west_2_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site_eu_west_2.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.app.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "site_eu_west_2" {
  certificate_arn         = aws_acm_certificate.site_eu_west_2.arn
  validation_record_fqdns = [for record in aws_route53_record.site_eu_west_2_validation : record.fqdn]
}

resource "aws_route53_record" "builder" {
  zone_id = aws_route53_zone.app.zone_id
  name    = local.builder_hostname
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "forge" {
  zone_id = aws_route53_zone.app.zone_id
  name    = local.forge_hostname
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
