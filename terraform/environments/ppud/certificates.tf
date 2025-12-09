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

########################
# Production Environment
########################

locals {
  prod_domains = local.is-production ? {
    "ppudprod"  = "ppud.justice.gov.uk"
    "wamprod"   = "wam.ppud.justice.gov.uk"
  } : {}
}

resource "aws_acm_certificate" "prod_certificates" {
  for_each                  = local.is-production ? local.prod_domains : {}
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

resource "aws_acm_certificate_validation" "prod_certificate_validation" {
  for_each        = local.is-production ? aws_acm_certificate.prod_certificates : {}
  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for option in each.value.domain_validation_options : option.resource_record_name
  ]
}

output "prod_cname_validation_records" {
  value = local.is-production ? {
    for cert_key, cert in aws_acm_certificate.prod_certificates : cert_key => [
      for option in cert.domain_validation_options : {
        name   = option.resource_record_name
        type   = option.resource_record_type
        value  = option.resource_record_value
      }
    ]
  } : {}
}