locals {

  acm_certificates_filter = flatten([
    var.options.enable_application_environment_wildcard_cert ? ["application_environment_wildcard_cert"] : []
  ])

  acm_certificates = {

    # wildcard cert, e.g. *.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk
    application_environment_wildcard_cert = {

      # domain_name limited to 64 chars so use modernisation platform domain for this
      # and put the wildcard in the san
      domain_name             = var.environment.domains.public.modernisation_platform
      subject_alternate_names = ["*.${var.environment.domains.public.application_environment}"]

      tags = {
        description = "wildcard cert for ${var.environment.domains.public.application_environment} domain"
      }
    }
  }

}

