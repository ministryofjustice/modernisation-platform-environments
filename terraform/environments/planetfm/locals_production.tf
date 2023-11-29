# nomis-production environment settings
locals {

  # baseline config
  production_config = {
    baseline_route53_zones = {
      "planetfm.service.justice.gov.uk" = {
        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1128.awsdns-13.org", "ns-2027.awsdns-61.co.uk", "ns-854.awsdns-42.net", "ns-90.awsdns-11.com"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1407.awsdns-47.org", "ns-1645.awsdns-13.co.uk", "ns-63.awsdns-07.com", "ns-730.awsdns-27.net"] },
        ]
      }
    }
  }
}
