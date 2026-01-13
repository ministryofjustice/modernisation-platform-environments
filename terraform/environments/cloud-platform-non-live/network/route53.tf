resource "aws_route53_zone" "temp_cloud_platform_justice_gov_uk" {
  count = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  name = "temp.cloud-platform.service.justice.gov.uk."
}
