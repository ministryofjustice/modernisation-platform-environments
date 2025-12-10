#########################################
# ACM Certifies for PPUD and WAM websites
#########################################

#########################
# Development Environment
#########################

# Prestaged ACM Development Certificates, which expire in March 2026
/*
locals {
  dev_domains = local.is-development ? {
    "internaltest"      = "internaltest.ppud.justice.gov.uk"
    "waminternaltest"   = "waminternaltest.ppud.justice.gov.uk"
  } : {}
}

resource "aws_acm_certificate" "dev_certificates" {
  for_each                  = local.is-development ? local.dev_domains : {}
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

resource "aws_acm_certificate_validation" "dev_certificate_validation" {
  for_each        = local.is-development ? aws_acm_certificate.dev_certificates : {}
  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for option in each.value.domain_validation_options : option.resource_record_name
  ]
}
*/

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
