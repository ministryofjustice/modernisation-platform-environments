resource "aws_route53_zone" "container_platform_service_justice_gov_uk" {
  count = local.environment == "live" ? 1 : 0
  name  = local.base_domain
}

resource "aws_route53_zone" "environment_container_platform_justice_gov_uk" {
  name = local.environment_configuration.account_subdomain_name
}

# NS delegation records from the root zone to each account-level zone.
# These are created only in the live workspace which owns the root zone.
# The NS values are hardcoded because they are auto-assigned by Route53 when
# each account zone is created and must be copied here manually.

resource "aws_route53_record" "development_ns" {
  count   = local.environment == "live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "development.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-245.awsdns-30.com.",
    "ns-1455.awsdns-53.org.",
    "ns-853.awsdns-42.net.",
    "ns-2000.awsdns-58.co.uk.",
  ]
}

resource "aws_route53_record" "preproduction_ns" {
  count   = local.environment == "live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "preproduction.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-1671.awsdns-16.co.uk.",
    "ns-376.awsdns-47.com.",
    "ns-1331.awsdns-38.org.",
    "ns-519.awsdns-00.net.",
  ]
}

resource "aws_route53_record" "nonlive_ns" {
  count   = local.environment == "live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "nonlive.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-955.awsdns-55.net.",
    "ns-1523.awsdns-62.org.",
    "ns-303.awsdns-37.com.",
    "ns-1718.awsdns-22.co.uk.",
  ]
}

resource "aws_route53_record" "live_ns" {
  count   = local.environment == "live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "live.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = aws_route53_zone.environment_container_platform_justice_gov_uk.name_servers
}