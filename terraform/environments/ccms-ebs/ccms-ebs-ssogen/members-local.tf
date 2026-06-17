#### This file can be used to store locals specific to the member account ####
locals {

  application_name_ssogen = "ssogen"

  # Certificate configuration based on environment
  nonprod_domain = format("%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
  prod_domain    = "laa.service.justice.gov.uk"

  # Primary domain name based on environment
  primary_domain = local.is-production ? local.prod_domain : local.nonprod_domain

  nonprod_sans = [
    format("ccmsebs-sso.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment),
    format("ccms-ssogen-as1.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment),
    format("ccms-ssogen-as2.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment),
    format("ccms-ssogen-admin.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment),
    format("ccmsebs-sso-admin.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
  ]

  prod_sans = [
    format("ccmsebs-sso.%s", local.prod_domain),
    format("ccmsebs-sso-admin.%s", local.prod_domain),
    format("ccms-ssogen-as1.%s", local.prod_domain),
    format("ccms-ssogen-as2.%s", local.prod_domain),
    format("ccms-ssogen-admin.%s", local.prod_domain)
  ]

  subject_alternative_names = local.is-production ? local.prod_sans : local.nonprod_sans
  # Domain validation options mapping (following the example pattern)
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  # Split domain validation by domain type
  modernisation_platform_validations = [for k, v in local.domain_types : v if strcontains(k, "modernisation-platform.service.justice.gov.uk")]
  laa_validations                    = [for k, v in local.domain_types : v if strcontains(k, "laa.service.justice.gov.uk")]

}
