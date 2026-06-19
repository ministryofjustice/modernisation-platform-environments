##############################################
### ACM Certificate for RADIUS Portal (LinOTP)
###
### Creates SSL certificate for user-facing
### MFA enrollment portal with DNS validation
##############################################

##############################################
### Locals for ACM Validation
##############################################
locals {
  # Extract domain validation options into a structured map
  radius_domain_types = {
    for dvo in aws_acm_certificate.radius_portal.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

##############################################
### ACM Certificate for RADIUS Portal ALB
##############################################
# Following OAS pattern: primary domain + SAN wildcard
resource "aws_acm_certificate" "radius_portal" {
  domain_name = "modernisation-platform.service.justice.gov.uk"

  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]

  validation_method = "DNS"

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}-${local.environment}-radius-portal-cert"
      "Purpose" = "RADIUS MFA Portal"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

##############################################
### Route53 DNS Records for Certificate Validation
### All records created in parent zone (core-network-services)
##############################################

resource "aws_route53_record" "radius_cert_validation" {
  for_each = local.radius_domain_types
  provider = aws.core-network-services

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

##############################################
### ACM Certificate Validation
##############################################
resource "aws_acm_certificate_validation" "radius_portal" {
  certificate_arn         = aws_acm_certificate.radius_portal.arn
  validation_record_fqdns = values(aws_route53_record.radius_cert_validation)[*].fqdn
}
