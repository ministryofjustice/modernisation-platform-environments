locals {
  production_config = {
    baseline_route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-1418.awsdns-49.org", "ns-230.awsdns-28.com", "ns-693.awsdns-22.net", "ns-1786.awsdns-31.co.uk"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" }
        ]
      }
    }
  }
}
