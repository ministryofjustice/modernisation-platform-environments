# ACM Public Certificate
data "aws_route53_zone" "modernisation_platform" {
  provider = aws.core-network-services
  name = "modernisation-platform.service.justice.gov.uk"
  private_zone = false
}

resource "aws_acm_certificate" "external" {
  domain_name               = local.is-production ? "correspondence-handling-and-processing.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  
  validation_method         = "DNS"

  subject_alternative_names = local.is-production ? ["correspondence-handling-and-processing.service.justice.gov.uk"] : ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn

  validation_record_fqdns = local.is-production ? [aws_route53_record.external_validation_prod[0].fqdn] : concat(aws_route53_record.external_validation_dev_parent[*].fqdn, aws_route53_record.external_validation_dev_app[*].fqdn)
}

# Route53 DNS records for certificate validation (prod)
resource "aws_route53_record" "external_validation_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.external.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.external.domain_validation_options)[0].resource_record_value]
  ttl             = 60
  type            = tolist(aws_acm_certificate.external.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.application_zone.zone_id
}

#Route53 DNS record for cart validation (dev only)
resource "aws_route53_record" "external_validation_dev_parent" {
  count = (!local.is-production && local.environment == "development" && contains(keys(local.domain_types), "modernisation-platform.service.justice.gov.uk")) ? 1 : 0
  provider = aws.core-network-services
  zone_id = data.aws_route53_zone.modernisation_platform.zone_id

  allow_overwrite = true

  name    = local.domain_types["modernisation-platform.service.justice.gov.uk"].name
  type    = local.domain_types["modernisation-platform.service.justice.gov.uk"].type
  ttl     = 60
  records = [local.domain_types["modernisation-platform.service.justice.gov.uk"].record]
}

#Route53 DNS record for cart validation (dev only)
resource "aws_route53_record" "external_validation_dev_app" {
  count = (!local.is-production && local.environment == "development" && contains(keys(local.domain_types), "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk")) ? 1 : 0
  provider = aws.core-network-services
  zone_id = data.aws_route53_zone.application_zone.zone_id

  allow_overwrite = true

  name    = local.domain_types["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"].name
  type    = local.domain_types["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"].type
  ttl     = 60
  records = [local.domain_types["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"].record]
}


# Production Route53 DNS record 
resource "aws_route53_record" "external_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.application_zone.zone_id
  name     = "correspondence-handling-and-processing.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = module.lb_access_logs_enabled.load_balancer.dns_name
    zone_id                = module.lb_access_logs_enabled.load_balancer.zone_id
    evaluate_target_health = true
  }
}



# Non-prod Route53 DNS record (dev only)
# Disabled for now – DNS managed elsewhere, avoids AccessDenied
#resource "aws_route53_record" "external_nonprod" {
#  count           = 0 #(!local.is-production && local.environment == "development") ? 1 : 0
#  provider        = aws.core-network-services
#  zone_id         = data.aws_route53_zone.application_zone.zone_id
#  name            = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#  type            = "A"
#  allow_overwrite = true

#  alias {
#    name                   = module.lb_access_logs_enabled.load_balancer.dns_name
#    zone_id                = module.lb_access_logs_enabled.load_balancer.zone_id
#    evaluate_target_health = true
#  }
#}
