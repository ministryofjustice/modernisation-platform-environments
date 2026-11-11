locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      route53_zones = {
        "development.engineering.justice.gov.uk" = {
          records = {}
        }
      }
    }
    test = {
      route53_zones = {
        "test.engineering.justice.gov.uk" = {
          records = {}
        }
      }
    }
    preproduction = {
      route53_zones = {
        "preproduction.engineering.justice.gov.uk" = {
          records = {}
        }
      }
    }
    production = {
      route53_zones = {
        "engineering.justice.gov.uk" = {
          records = {}
        }
      }
    }
  }
}
