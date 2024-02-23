locals {
  preproduction_config = {
    baseline_route53_zones = {
      "preproduction.ndh.nomis.service.justice.gov.uk" = {
        records = []
      }
    }
  }
}
