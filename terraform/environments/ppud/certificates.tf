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
    "uat"    = "uat.ppud.justice.gov.uk"
    "wamuat" = "wamuat.ppud.justice.gov.uk"
  } : {}
}

resource "aws_acm_certificate" "uat_certificates" {
  for_each                  = local.preprod_domains
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

resource "aws_acm_certificate_validation" "uat_certificate_validation" {
  for_each = aws_acm_certificate.uat_certificates

  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for record_key, record in aws_route53_record.uat_dns_record :
    record.fqdn if startswith(record_key, each.key)
  ]
  depends_on = [
    aws_route53_record.uat_dns_record
  ]
}

locals {
  uat_dns_records = {
    for cert_key, cert in aws_acm_certificate.uat_certificates :
    for option in cert.domain_validation_options :
    "${cert_key}-${option.resource_record_name}" => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  }
}

resource "aws_route53_record" "uat_dns_record" {
  for_each = local.uat_dns_records

  provider = aws.core-network-services

  allow_overwrite = true
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
  # zone_id = var.shared_zone_id      # shared hosted zone
  zone_id = each.value.zone.zone_id   # multiple zones
}


########################
# Production Environment
########################