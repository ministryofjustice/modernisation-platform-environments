locals {

  acm_certificates = {

    #--------------------------------------------------------------------------
    # define certificates common to all environments here
    #--------------------------------------------------------------------------
    common = {
      # e.g. star.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk
      "star.${module.environment.domains.public.application_environment}" = {
        # domain_name limited to 64 chars so put it in the san instead
        domain_name             = module.environment.domains.public.modernisation_platform
        subject_alternate_names = ["*.${module.environment.domains.public.application_environment}"]
        validation = {
          "${module.environment.domains.public.modernisation_platform}" = {
            account   = "core-network-services"
            zone_name = "${module.environment.domains.public.modernisation_platform}."
          }
          "*.${module.environment.domains.public.application_environment}" = {
            account   = "core-vpc"
            zone_name = "${module.environment.domains.public.business_unit_environment}."
          }
        }
        tags = {
          description = "wildcard cert for ${module.environment.domains.public.application_environment} domain"
        }
      }
    }

    #--------------------------------------------------------------------------
    # define environment specific certificates here
    #--------------------------------------------------------------------------

    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}
