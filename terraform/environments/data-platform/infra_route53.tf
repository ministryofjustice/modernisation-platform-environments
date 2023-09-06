##################################################
# Development
##################################################

resource "aws_route53_zone" "development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "development" ? 1 : 0

  name = "development.data-platform.service.justice.gov.uk"
  tags = local.tags
}

# Delegating to data-platform-apps-and-tools-development
resource "aws_route53_record" "delegate_apps_tools_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "development" ? 1 : 0

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

##################################################
# Test
##################################################

resource "aws_route53_zone" "test_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "test" ? 1 : 0

  name = "test.data-platform.service.justice.gov.uk"
  tags = local.tags
}

##################################################
# PreProduction
##################################################

resource "aws_route53_zone" "preproduction_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "preproduction" ? 1 : 0

  name = "preproduction.data-platform.service.justice.gov.uk"
  tags = local.tags
}

##################################################
# Production
##################################################

resource "aws_route53_zone" "data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "production" ? 1 : 0

  name = "data-platform.service.justice.gov.uk"
  tags = local.tags
}

resource "aws_route53_record" "delegate_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk.zone_id
  name    = "development.data-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = "300"
  records = [
    "ns-1741.awsdns-25.co.uk.",
    "ns-446.awsdns-55.com.",
    "ns-1406.awsdns-47.org.",
    "ns-952.awsdns-55.net."
  ]
}
