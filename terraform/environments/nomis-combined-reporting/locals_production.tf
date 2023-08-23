locals {
  production_config = {

    baseline_route53_zones = {
      "reporting.nomis.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-104.awsdns-13.com", "ns-1357.awsdns-41.org", "ns-1718.awsdns-22.co.uk", "ns-812.awsdns-37.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1011.awsdns-62.net", "ns-1090.awsdns-08.org", "ns-1938.awsdns-50.co.uk", "ns-390.awsdns-48.com"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1525.awsdns-62.org", "ns-1563.awsdns-03.co.uk", "ns-38.awsdns-04.com", "ns-555.awsdns-05.net"] },
        ]
      }
      "production.reporting.nomis.service.justice.gov.uk" = {
      }
      
    }

  }
}
