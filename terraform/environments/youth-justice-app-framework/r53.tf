import {
  to = aws_route53_record.private_alb
  id = "Z08455115FU5NW9YGUX1_db-yjafrds01.test.yjaf_CNAME"
}
#If route53_record_name set do this
resource "aws_route53_record" "dbdns" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "db-yjafrds01"
  type    = "CNAME"
  ttl     = 300
  records = [module.aurora.rds_cluster_endpoint]
}

resource "aws_route53_record" "private_alb" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.yjaf-inner.id
  name    = "private-lb"
  type    = "CNAME"
  ttl     = 300
  records = [module.internal_alb.dns_name]
}
