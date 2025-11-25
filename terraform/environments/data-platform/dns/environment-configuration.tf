locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      route53_zone_name = "development.data-platform.service.justice.gov.uk"
      route53_records = {
        llm-gateway-ns = {
          /* 
            Delegate llm-gateway to Cloud Platform 
            https://github.com/ministryofjustice/cloud-platform-environments/blob/main/namespaces/live.cloud-platform.service.justice.gov.uk/data-platform-llm-gateway-development/resources/route53.tf
          */
          type = "NS"
          name = "llm-gateway"
          ttl  = 86400
          records = [
            "ns-1340.awsdns-39.org.",
            "ns-1602.awsdns-08.co.uk.",
            "ns-440.awsdns-55.com.",
            "ns-885.awsdns-46.net."
          ]
        }
      }
    }
    test = {
      route53_zone_name = "test.data-platform.service.justice.gov.uk"
      route53_records   = {}
    }
    preproduction = {
      route53_zone_name = "preproduction.data-platform.service.justice.gov.uk"
      route53_records   = {}
    }
    production = {
      route53_zone_name = "data-platform.service.justice.gov.uk"
      route53_records = {
        /* Zone Delegation */
        development-ns = {
          type = "NS"
          name = "development"
          ttl  = 86400
          records = [
            "ns-131.awsdns-16.com.",
            "ns-1777.awsdns-30.co.uk.",
            "ns-1189.awsdns-20.org.",
            "ns-1012.awsdns-62.net."
          ]
        },
        preproduction-ns = {
          type = "NS"
          name = "preproduction"
          ttl  = 86400
          records = [
            "ns-1692.awsdns-19.co.uk.",
            "ns-1427.awsdns-50.org.",
            "ns-638.awsdns-15.net.",
            "ns-182.awsdns-22.com."
          ]
        },
        test-ns = {
          type = "NS"
          name = "test"
          ttl  = 86400
          records = [
            "ns-31.awsdns-03.com.",
            "ns-1449.awsdns-53.org.",
            "ns-1599.awsdns-07.co.uk.",
            "ns-674.awsdns-20.net."
          ]
        }
      }
    }
  }
}
