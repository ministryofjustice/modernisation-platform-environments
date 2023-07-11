resource "aws_route53_zone" "development_data_platform_service_justice_gov_uk" {
  name = "development.data-platform.service.justice.gov.uk"
  tags = local.tags
}

resource "aws_route53_record" "apps_tools_development_data_platform_service_justice_gov_uk" {
  zone_id = aws_route53_zone.development_data_platform_service_justice_gov_uk.zone_id
  name    = "apps-tools.development.data-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = "300"
  records = [
    "ns-1673.awsdns-17.co.uk",
    "ns-1230.awsdns-25.org",
    "ns-122.awsdns-15.com",
    "ns-876.awsdns-45.net"
  ]
}
