# ACM certificate validation
resource "aws_acm_certificate_validation" "external" {
  certificate_arn = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

# One route53 record required for each domain listed in the external certificate
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.external.zone_id
}

// Create one Route 53 record for each entry in the list of tribunals (assigned in platform_locals.tf)
resource "aws_route53_record" "external" {
  provider = aws.core-vpc
  count = length(local.tribunal_names)
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.tribunal_names[count.index]}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.ecs_loadbalancer.tribunals_lb.dns_name
    zone_id                = module.ecs_loadbalancer.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

# Define a wildcard ACM certificate for sandbox/dev
resource "aws_acm_certificate" "external" {
  domain_name       = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.external.arn
}

output "acm_certificate_validation_dns" {
  value = [for dvo in aws_acm_certificate.external.domain_validation_options : dvo.resource_record_name]
}

output "acm_certificate_validation_route53" {
  value = [for dvo in aws_acm_certificate.external.domain_validation_options : dvo.resource_record_value]
}