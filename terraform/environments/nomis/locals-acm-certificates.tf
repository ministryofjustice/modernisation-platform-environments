locals {

  certificate = {
    modernisation_platform_top_level = {
      domain_name = "modernisation-platform.service.justice.gov.uk"
      zone_name   = "modernisation-platform.service.justice.gov.uk"
    }
    modernisation_platform_wildcard = {
      name        = "star.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
      zone_name   = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
      domain_name = "*.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    }
  }

  acm_certificates = {

    common = {
      # define certs common to all environments
      "${local.certificate.modernisation_platform_wildcard.name}" = {
        # domain_name limited to 64 chars so put it in the san instead
        domain_name             = local.certificate.modernisation_platform_top_level.domain_name
        subject_alternate_names = [local.certificate.modernisation_platform_wildcard.domain_name]
        validation = {
          "modernisation-platform.service.justice.gov.uk" = {
            account   = "core-network-services"
            zone_name = "${local.certificate.modernisation_platform_top_level.zone_name}."
          }
          "${local.certificate.modernisation_platform_wildcard.domain_name}" = {
            account   = "core-vpc"
            zone_name = "${local.certificate.modernisation_platform_wildcard.zone_name}."
          }
        }
        tags = {
          description = "wildcard cert for ${local.certificate.modernisation_platform_wildcard.zone_name} domain"
        }
      }
    }

    # define environmental specific certs here
    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}
