locals {
  production_config = {

    baseline_route53_zones = {
      "reporting.nomis.service.justice.gov.uk" = {
        # { name = "preproduction", type = "NS", ttl = "300", records = ["t1ncr-a.test.reporting.nomis.service.justice.gov.uk"] },
        # { name = "development", type = "NS", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        # { name = "test", type = "NS", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
      }
      "production.reporting.nomis.service.justice.gov.uk" = {
      }
      
    }

  }
}
