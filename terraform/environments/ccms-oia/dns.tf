# DNS Configuration

resource "aws_route53_record" "route53_record_oia" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_name
  type     = "A"

  alias {
    name                   = aws_lb.oia.dns_name
    zone_id                = aws_lb.oia.zone_id
    evaluate_target_health = false
  }
}
