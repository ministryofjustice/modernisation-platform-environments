resource "aws_route53_record" "prd-mojfin-rds" {
  count    = local.environment == "production" ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.laa-finance.zone_id
  name     = "rds.${local.prod_domain_name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.appdb1.address]
}

resource "aws_route53_record" "nonprd-mojfin-rds" {
  count    = local.environment != "production" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.appdb1.address]
}
