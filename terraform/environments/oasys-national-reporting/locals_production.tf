locals {

  # baseline config
  production_config = {
    baseline_route53_zones = {
      "reporting.oasys.service.justice.gov.uk" = {}
    }  
  }
}
