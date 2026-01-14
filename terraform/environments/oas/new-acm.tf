##############################################
### Locals for ACM Validation ###
##############################################
locals {
  # Extract domain validation options into a structured map
  domain_types = contains(["test", "preproduction"], local.environment) ? {
    for dvo in aws_acm_certificate.external[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
}

# Data source for parent zone (for certificate validation)
data "aws_route53_zone" "modernisation_platform" {
  provider     = aws.core-network-services
  name         = "modernisation-platform.service.justice.gov.uk"
  private_zone = false
}

##############################################
### ACM CERTIFICATE FOR LOAD BALANCER ###
##############################################
# ACM Public Certificate for test and preproduction environments
# Test uses zone-specific wildcard (57 chars) - preproduction uses parent wildcard (48 chars)
resource "aws_acm_certificate" "external" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  domain_name       = local.environment == "test" ? "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk" : "*.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-lb-certificate" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 DNS records for certificate validation
# Test validates in laa-test zone, preproduction validates in parent zone
resource "aws_route53_record" "external_validation" {
  for_each = local.domain_types
  provider = local.environment == "test" ? aws.core-vpc : aws.core-network-services

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.environment == "test" ? data.aws_route53_zone.external.zone_id : data.aws_route53_zone.modernisation_platform.zone_id
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "external" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = values(aws_route53_record.external_validation)[*].fqdn
}