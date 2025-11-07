#########################################
# SSOGEN Internal Load Balancer DNS Records
#########################################

# Non-prod SSOGEN ALB record
resource "aws_route53_record" "ssogen_internal_alb" {
  count    = local.is-development ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccmsebs-sso"
  type    = "A"

  alias {
    name                   = aws_lb.ssogen_alb.dns_name
    zone_id                = aws_lb.ssogen_alb.zone_id
    evaluate_target_health = true
  }
}