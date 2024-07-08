locals {

  baseline_presets_test = {
    options = {}
  }

  # please keep resources in alphabetical order
  baseline_test = {

    route53_zones = {
      "test.planetfm.service.justice.gov.uk" = {}
    }
  }
}
