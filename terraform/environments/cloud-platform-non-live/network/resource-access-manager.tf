resource "aws_ram_resource_share" "route53_zone_share" {
  count = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  name                      = "route53-zone-share"
  allow_external_principals = false

  tags = {
    Environment = "Production"
  }
}

resource "aws_ram_resource_association" "route53_zone_association" {
  count              = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  resource_arn       = aws_route53_zone.temp_cloud_platform_justice_gov_uk[0].arn
  resource_share_arn = aws_ram_resource_share.route53_zone_share[0].arn
}

resource "aws_ram_principal_association" "route53_zone_share" {
  for_each = terraform.workspace == "cloud-platform-non-live-production" ? toset([
    "cloud-platform-non-live-development",
    "cloud-platform-non-live-test",
    "cloud-platform-non-live-preproduction"
  ]) : []

  principal          = local.environment_management.account_ids[each.key]
  resource_share_arn = aws_ram_resource_share.route53_zone_share[0].arn
}