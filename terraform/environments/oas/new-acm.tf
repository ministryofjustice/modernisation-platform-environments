##############################################
### Locals for ACM Validation ###
##############################################
locals {
  # Extract domain validation options into a structured map
  domain_types = contains(["test", "preproduction", "production"], local.environment) ? {
    for dvo in aws_acm_certificate.external[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  # Split domains: parent (modernisation-platform) vs environment-specific (laa-test/laa-preproduction)
  parent_domain_validation = contains(["test", "preproduction", "production"], local.environment) ? {
    for k, v in local.domain_types : k => v
    if k == "modernisation-platform.service.justice.gov.uk"
  } : {}

  env_domain_validation = contains(["test", "preproduction", "production"], local.environment) ? {
    for k, v in local.domain_types : k => v
    if k != "modernisation-platform.service.justice.gov.uk"
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
# ACM Public Certificate for test, preproduction and production environments
# Using parent domain as primary (48 chars) with environment-specific SANs
resource "aws_acm_certificate" "external" {
  count = contains(["test", "preproduction", "production"], local.environment) ? 1 : 0

  domain_name = "modernisation-platform.service.justice.gov.uk"

  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]

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
# Parent domain validates in parent zone
resource "aws_route53_record" "external_validation_parent" {
  for_each = local.parent_domain_validation
  provider = aws.core-network-services

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.modernisation_platform.zone_id
}

# Environment-specific domains validate in environment zone
resource "aws_route53_record" "external_validation_env" {
  for_each = local.env_domain_validation
  provider = aws.core-vpc

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "external" {
  count = contains(["test", "preproduction", "production"], local.environment) ? 1 : 0

  certificate_arn = aws_acm_certificate.external[0].arn
  validation_record_fqdns = concat(
    values(aws_route53_record.external_validation_parent)[*].fqdn,
    values(aws_route53_record.external_validation_env)[*].fqdn
  )
}