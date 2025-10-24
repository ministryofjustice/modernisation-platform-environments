#########################################
# ACM Certifies for PPUD and WAM websites
#########################################

#########################
# Development Environment
#########################



###########################
# Preproduction Environment
###########################

locals {
  preprod_domains = local.is-preproduction ? {
    "uat"      = "uat.ppud.justice.gov.uk"
    "wamuat"   = "wamuat.ppud.justice.gov.uk"
    "training" = "training.ppud.justice.gov.uk"
  } : {}
}

resource "aws_acm_certificate" "preprod_certificates" {
  for_each                  = local.is-preproduction ? local.preprod_domains : {}
  domain_name               = each.value
  validation_method         = "DNS"
  subject_alternative_names = ["www.${each.value}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${each.value} certificate"
  }
}

# Output only needs to be enabled to view the CNAME records required for the justice.gov.uk DNS zone.
/*
output "preprod_cname_validation_records" {
  value = local.is-preproduction ? {
    for cert_key, cert in aws_acm_certificate.preprod_certificates : cert_key => [
      for option in cert.domain_validation_options : {
        name   = option.resource_record_name
        type   = option.resource_record_type
        value  = option.resource_record_value
      }
    ]
  } : {}
}
*/

resource "aws_acm_certificate_validation" "preprod_certificate_validation" {
  for_each        = local.is-preproduction ? aws_acm_certificate.preprod_certificates : {}
  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for option in each.value.domain_validation_options : option.resource_record_name
  ]
}

/*
locals {
  preprod_dns_records = local.is-preproduction ? merge([
    for cert_key, cert in aws_acm_certificate.preprod_certificates : {
      for option in cert.domain_validation_options : "${cert_key}-${option.resource_record_name}" => {
        name    = option.resource_record_name
        type    = option.resource_record_type
        record  = option.resource_record_value
        zone_id = data.aws_route53_zone.ppud.zone_id
      }
    }
  ]...) : {}
}

resource "aws_route53_record" "preprod_dns_record" {
  for_each = local.is-preproduction ? local.preprod_dns_records : {}
  provider = aws.core-network-services

  allow_overwrite = true
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
  zone_id = each.value.zone_id
}

resource "aws_acm_certificate_validation" "preprod_certificate_validation" {
  for_each = local.is-preproduction ? aws_acm_certificate.preprod_certificates : {}
  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for record_key, record in aws_route53_record.preprod_dns_record :
    record.fqdn if startswith(record_key, each.key)
  ]
  depends_on = [
    aws_route53_record.preprod_dns_record
  ]
}
*/

########################
# Production Environment
########################