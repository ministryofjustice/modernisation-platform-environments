resource "aws_route53_zone" "container_platform_service_justice_gov_uk" {
  count = local.environment == "live" ? 1 : 0
  name = local.base_domain
}

resource "aws_route53_zone" "environment_container_platform_justice_gov_uk" {
  name = local.environment_configuration.account_subdomain_name
}