locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      route53_zone_name = "development.data-platform.service.justice.gov.uk"
    }
    test = {
      route53_zone_name = "test.data-platform.service.justice.gov.uk"
    }
    preproduction = {
      route53_zone_name = "preproduction.data-platform.service.justice.gov.uk"
    }
    production = {
      route53_zone_name = "data-platform.service.justice.gov.uk"
    }
  }
}
