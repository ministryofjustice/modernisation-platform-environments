locals {

  baseline_presets_test = {
    options = {
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    security_groups = local.security_groups
    route53_zones = {
      "test.csr.service.justice.gov.uk" = {}
    }
  }
}
