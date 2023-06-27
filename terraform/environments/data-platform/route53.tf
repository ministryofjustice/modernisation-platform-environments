resource "aws_route53_zone" "development_data_platform_service_justice_gov_uk" {
  name = "development.data-platform.service.justice.gov.uk"
  tags = local.tags
}
