##############################################
### Route53 DNS Record for RADIUS Portal
###
### Creates user-facing DNS name for LinOTP
### MFA enrollment portal
##############################################

resource "aws_route53_record" "radius_portal" {

  
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "workspace-new-mfa.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = aws_lb.radius_portal.dns_name
    zone_id                = aws_lb.radius_portal.zone_id
    evaluate_target_health = true
  }
}
