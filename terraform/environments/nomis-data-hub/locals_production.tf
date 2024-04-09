locals {
  production_config = {
    baseline_route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-175.awsdns-21.com", "ns-1492.awsdns-58.org", "ns-1647.awsdns-13.co.uk", "ns-535.awsdns-02.net"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" }
        ]
      }
    }
  }
}
