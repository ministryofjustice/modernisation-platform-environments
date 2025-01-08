#If route53_record_name set do this
#resource "aws_route53_record" "dbdns" {
#  provider = aws.core-network-services

#  zone_id = data.aws_route53_zone.yjaf-inner.id
#  name    = module.aurora.rds_cluster_endpoint
#  type    = "CNAME"
#  ttl     = 300
#  records = ["db-yjafrds01"]
#}
