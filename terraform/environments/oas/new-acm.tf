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
# Using wildcard on parent domain (48 chars) to cover laa-preproduction subdomain
resource "aws_acm_certificate" "external" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  domain_name       = "*.modernisation-platform.service.justice.gov.uk"
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
resource "aws_route53_record" "external_validation" {
  for_each = local.domain_types
  provider = aws.core-network-services

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.modernisation_platform.zone_id
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "external" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = values(aws_route53_record.external_validation)[*].fqdn
}