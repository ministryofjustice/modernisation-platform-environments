resource "aws_route53_zone" "temp_cloud_platform_justice_gov_uk" {
  count = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  name  = "${local.base_domain}."
}

resource "aws_route53_zone" "account_zone" {
  name = "${trimprefix(terraform.workspace, "cloud-platform-")}.${local.base_domain}"
}

resource "aws_route53_record" "account_delegation" {
  for_each = terraform.workspace == "cloud-platform-non-live-production" ? local.environment_configurations : {}
  zone_id  = aws_route53_zone.temp_cloud_platform_justice_gov_uk[0].zone_id
  name     = each.value.account_subdomain_name
  type     = "NS"
  ttl      = 300
  records  = each.value.ns_records

  depends_on = [ aws_iam_policy.github_actions_assume_hosted_zones_role ]
}