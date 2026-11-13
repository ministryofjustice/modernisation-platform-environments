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
          records = {
            sts-github-ns = {
              type = "NS"
              name = "sts.github"
              ttl  = 86400
              records = [
                "ns-1368.awsdns-43.org.",
                "ns-1996.awsdns-57.co.uk.",
                "ns-375.awsdns-46.com.",
                "ns-806.awsdns-36.net."
              ]
            }
          }
        }
      }
    }
  }
}
