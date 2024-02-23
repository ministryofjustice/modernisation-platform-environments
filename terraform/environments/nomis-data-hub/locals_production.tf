locals {
  production_config = {
    baseline_route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-1411.awsdns-48.org", "ns-885.awsdns-46.net", "ns-56.awsdns-07.com", "ns-1799.awsdns-32.co.uk"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" }
        ]
      }
    }
  }
}
