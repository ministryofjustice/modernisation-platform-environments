resource "aws_route53_record" "external_sandbox" {
  count = local.is-development ? 1 : 0

  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.sandbox_app_url
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}