locals {
  production_config = {
    baseline_route53_zones = {
      "ndh.nomis.service.justice.gov.uk " = {
        records = []
      }
    }
  }
}
