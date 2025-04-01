##################################################
# Production
##################################################

resource "aws_route53_zone" "data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  name = "data-platform.service.justice.gov.uk"
  tags = local.tags
}

# delegating to data-platform-apps-and-tools-production
resource "aws_route53_record" "delegate_apps_tools_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "apps-tools.data-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = "300"
  records = [
    "ns-1707.awsdns-21.co.uk.",
    "ns-492.awsdns-61.com.",
    "ns-1189.awsdns-20.org.",
    "ns-581.awsdns-08.net."
  ]
}

# Delegating to data-platform-development
resource "aws_route53_record" "delegate_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
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

# Delegating to data-platform-preproduction
resource "aws_route53_record" "delegate_preproduction_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "preproduction.data-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = "300"
  records = [
    "ns-328.awsdns-41.com.",
    "ns-1671.awsdns-16.co.uk.",
    "ns-792.awsdns-35.net.",
    "ns-1106.awsdns-10.org."
  ]
}

# Delegating to data-platform-test
resource "aws_route53_record" "delegate_test_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "test.data-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = "300"
  records = [
    "ns-407.awsdns-50.com.",
    "ns-1837.awsdns-37.co.uk.",
    "ns-681.awsdns-21.net.",
    "ns-1302.awsdns-34.org."
  ]
}

# Delegating to data-platform-apps-and-tools-production
resource "aws_route53_record" "delegate_assets_production_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "assets.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ingress.apps-tools.data-platform.service.justice.gov.uk."]
}

# Delegating to data-platform-apps-and-tools-production
resource "aws_route53_record" "delegate_control_panel_production_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "control-panel.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ingress.apps-tools.data-platform.service.justice.gov.uk."]
}

# Auth0
resource "aws_route53_record" "auth_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zone_id = aws_route53_zone.data_platform_service_justice_gov_uk[0].zone_id
  name    = "auth.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ministryofjustice-data-platform-cd-dk5jlhurgfon6kxk.edge.tenants.uk.auth0.com."]
}

##################################################
# Development
##################################################

resource "aws_route53_zone" "development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  name = "development.data-platform.service.justice.gov.uk"
  tags = local.tags
}

# Delegating to data-platform-apps-and-tools-development
resource "aws_route53_record" "delegate_apps_tools_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  zone_id = aws_route53_zone.development_data_platform_service_justice_gov_uk[0].zone_id
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

# Delegating to data-platform-apps-and-tools-development
resource "aws_route53_record" "delegate_assets_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  zone_id = aws_route53_zone.development_data_platform_service_justice_gov_uk[0].zone_id
  name    = "assets.development.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ingress.apps-tools.development.data-platform.service.justice.gov.uk."]
}

# Delegating to data-platform-apps-and-tools-development
resource "aws_route53_record" "delegate_control_panel_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  zone_id = aws_route53_zone.development_data_platform_service_justice_gov_uk[0].zone_id
  name    = "control-panel.development.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ingress.apps-tools.development.data-platform.service.justice.gov.uk."]
}

# Auth0
resource "aws_route53_record" "auth_development_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  zone_id = aws_route53_zone.development_data_platform_service_justice_gov_uk[0].zone_id
  name    = "auth.development.data-platform.service.justice.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["ministryofjustice-data-platform-development-cd-zvdb1vq1ynemnuqs.edge.tenants.uk.auth0.com."]
}

##################################################
# PreProduction
##################################################

resource "aws_route53_zone" "preproduction_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-preproduction" ? 1 : 0

  name = "preproduction.data-platform.service.justice.gov.uk"
  tags = local.tags
}

##################################################
# Test
##################################################

resource "aws_route53_zone" "test_data_platform_service_justice_gov_uk" {
  count = terraform.workspace == "data-platform-test" ? 1 : 0

  name = "test.data-platform.service.justice.gov.uk"
  tags = local.tags
}
