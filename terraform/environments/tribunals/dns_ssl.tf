variable "record_names" {
  type    = list(string)
  default = ["transportappeals", "administrativeappeals"]
}

# ACM certificate validation
# Just validate on the main domain name record
resource "aws_acm_certificate_validation" "external" {
  certificate_arn = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services
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
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

// Create one Route 53 record for each entry in record names
resource "aws_route53_record" "external" {
  provider = aws.core-vpc
  count = length(var.record_names)
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.record_names[count.index]}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tribunals_lb.dns_name
    zone_id                = aws_lb.tribunals_lb.zone_id
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

output "domain_name_main_0" {
  value = local.domain_name_main[0]
}

output "domain_name_sub_0" {
  value = local.domain_name_sub[0]
}

//// Route53 DNS records for certificate validation
//resource "aws_acm_certificate_validation" "external" {
//  certificate_arn         = aws_acm_certificate.external.arn
//  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
//}
//
//resource "aws_route53_record" "external_validation" {
//  provider = aws.core-network-services
//
//  allow_overwrite = true
//  name            = local.domain_name_main[0]
//  records         = local.domain_record_main
//  ttl             = 60
//  type            = local.domain_type_main[0]
//  zone_id         = data.aws_route53_zone.network-services.zone_id
//}
//
//resource "aws_route53_record" "external_validation_subdomain" {
//  provider = aws.core-vpc
//
//  allow_overwrite = true
//  name            = local.domain_name_sub[0]
//  records         = local.domain_record_sub
//  ttl             = 60
//  type            = local.domain_type_sub[0]
//  zone_id         = data.aws_route53_zone.external.zone_id
//}