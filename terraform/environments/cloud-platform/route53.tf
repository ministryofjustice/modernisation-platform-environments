resource "aws_route53_zone" "container_platform_service_justice_gov_uk" {
  count = terraform.workspace == "cloud-platform-live" ? 1 : 0
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
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
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
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
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
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
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
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "live.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = aws_route53_zone.environment_container_platform_justice_gov_uk.name_servers
}

# Business unit records
resource "aws_route53_record" "octo_nonlive_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "octo-nonlive.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-345.awsdns-43.com.",
    "ns-621.awsdns-13.net.",
    "ns-1186.awsdns-20.org.",
    "ns-1597.awsdns-07.co.uk.",
  ]
}

resource "aws_route53_record" "octo_live_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "octo-live.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-1377.awsdns-44.org.",
    "ns-320.awsdns-40.com.",
    "ns-1835.awsdns-37.co.uk.",
    "ns-691.awsdns-22.net.",
  ]
}

resource "aws_route53_record" "laa_nonlive_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "laa-nonlive.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-849.awsdns-42.net.",
    "ns-84.awsdns-10.com.",
    "ns-1915.awsdns-47.co.uk.",
    "ns-1027.awsdns-00.org.",
  ]
}

resource "aws_route53_record" "laa_live_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "laa-live.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-687.awsdns-21.net.",
    "ns-157.awsdns-19.com.",
    "ns-1197.awsdns-21.org.",
    "ns-1996.awsdns-57.co.uk.",
  ]
}

resource "aws_route53_record" "hmpps_nonlive_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "hmpps-nonlive.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-2039.awsdns-62.co.uk.",
    "ns-1120.awsdns-12.org.",
    "ns-548.awsdns-04.net.",
    "ns-416.awsdns-52.com.",
  ]
}

resource "aws_route53_record" "hmpps_live_ns" {
  count   = terraform.workspace == "cloud-platform-live" ? 1 : 0
  zone_id = aws_route53_zone.container_platform_service_justice_gov_uk[0].zone_id
  name    = "hmpps-live.${local.base_domain}"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-1969.awsdns-54.co.uk.",
    "ns-991.awsdns-59.net.",
    "ns-241.awsdns-30.com.",
    "ns-1290.awsdns-33.org.",
  ]
}
