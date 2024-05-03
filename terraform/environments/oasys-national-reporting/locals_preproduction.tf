locals {

  # baseline config
  preproduction_config = {
    baseline_route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
