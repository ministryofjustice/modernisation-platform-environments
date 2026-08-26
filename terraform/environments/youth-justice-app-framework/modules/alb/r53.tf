#If route53_record_name set do this
#resource "aws_route53_record" "dns" {
#  provider = aws.core-network-services
#  count    = var.alb_route53_record_name != "" ? 1 : 0

#  zone_id = var.alb_route53_record_zone_id
#  name    = module.alb.dns_name
#  type    = "CNAME"
#  ttl     = 300
#  records = [var.alb_route53_record_name]
#}
