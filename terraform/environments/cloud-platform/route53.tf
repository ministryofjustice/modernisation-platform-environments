resource "aws_route53_zone" "temp_cloud_platform_justice_gov_uk" {
  name  = local.environment_configuration.account_subdomain_name
}