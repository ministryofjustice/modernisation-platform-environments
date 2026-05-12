##############################################
### Route53 DNS Record for RADIUS Portal
###
### Creates user-facing DNS name for LinOTP
### MFA enrollment portal
##############################################

resource "aws_route53_record" "radius_portal" {
  count = local.environment == "development" ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "workspace-mfa.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = aws_lb.radius_portal[0].dns_name
    zone_id                = aws_lb.radius_portal[0].zone_id
    evaluate_target_health = true
  }
}
