#If route53_record_name set do this
resource "aws_route53_record" "dbdns" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "db-yjafrds01"
  type    = "CNAME"
  ttl     = 300
  records = [module.aurora.rds_cluster_endpoint]
}

resource "aws_route53_record" "dbdns-ro" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "db-yjafrds01-reader"
  type    = "CNAME"
  ttl     = 300
  records = [module.aurora.rds_cluster_reader_endpoint]
}

resource "aws_route53_record" "redshift" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "redshift"
  type    = "CNAME"
  ttl     = 300
  records = [module.redshift.address]
}

resource "aws_route53_record" "private_alb" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "private-lb"
  type    = "CNAME"
  ttl     = 300
  records = [module.internal_alb.dns_name]
}

locals {
  dns_a_records = {
    assets = [module.yjsm.yjsm_instance_private_ip]
    mule   = [module.esb.esb_instance_private_ip]
    ldap   = module.ds.dns_ip_addresses
  }
}

resource "aws_route53_record" "type_a" {
  # checkov:skip=CKV2_AWS_23: "Referenced resources are in a different account."

  provider = aws.core-network-services

  for_each = local.dns_a_records

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = each.value
}

/*
resource "aws_route53_record" "assets" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "assets"
  type    = "A"
  ttl     = 300
  records = [module.yjsm.yjsm_instance_private_ip]
}

resource "aws_route53_record" "mule" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "mule"
  type    = "A"
  ttl     = 300
  records = [module.esb.esb_instance_private_ip]
}


resource "aws_route53_record" "ldap" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "ldap"
  type    = "A"
  ttl     = 300
  records = [module.ds.dns_ip_addresses]
}
*/