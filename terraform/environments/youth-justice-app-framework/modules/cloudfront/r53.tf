#If route53_record_name set do this
resource "aws_route53_record" "dbdns" {
  count   = var.cloudfront_route53_record_name != "" ? 1 : 0
  zone_id = var.r53_zone_id
  name    = var.cloudfront_route53_record_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.external.domain_name]
}
