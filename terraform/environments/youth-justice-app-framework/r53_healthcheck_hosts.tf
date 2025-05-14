locals {
  list_of_service_names = [
    "ui",
    "bands",
    "bu",
    "case",
    "cmm",
    "conversions",
    "dal",
    "documents",
    "gateway",
    "placements",
    "refdata",
    "returns",
    "serious-incidents",
    "transfers",
    "views",
    "workflow",
    "sentences",
    "transitions",
    "yp",
    "auth"
  ]
}

resource "aws_route53_record" "healthcheck_hostnames" {
  for_each = toset(local.list_of_service_names)
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = each.key
  type    = "CNAME"
  ttl     = 300
  records = [module.internal_alb.dns_name]
}
