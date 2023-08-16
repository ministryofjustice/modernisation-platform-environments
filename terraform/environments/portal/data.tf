data "aws_route53_zone" "portal-dev-private" {
  for_each = local.core_network_services_domains_private
  provider = aws.core-network-services

  name         = "dev.legalservices.gov.uk."
  private_zone = true
}

data "aws_route53_zone" "core_network_services" {
  for_each = local.core_network_services_domains

  provider = aws.core-network-services

  name         = each.value.zone_name
  private_zone = false
}

data "aws_route53_zone" "core_vpc" {
  for_each = local.core_vpc_domains

  provider = aws.core-vpc

  name         = each.value.zone_name
  private_zone = false
}

data "aws_route53_zone" "self" {
  for_each = local.self_domains

  name         = each.value.zone_name
  private_zone = false
}
