module "production_records" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/records?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_name = "data-platform.service.justice.gov.uk"

  records = [
    /* Zone Delegation */
    {
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
    {
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
    {
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
  ]
}
