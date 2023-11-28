# nomis-production environment settings
locals {

  # baseline config
  production_config = {
    baseline_route53_zones = {
      "planetfm.service.justice.gov.uk" = {}
    }
  }
}
