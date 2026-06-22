##############################################
### Route53 DNS Record for RADIUS Portal
###
### Creates user-facing DNS name for LinOTP
### MFA enrollment portal in parent zone
##############################################

resource "aws_route53_record" "radius_portal" {
  provider = aws.core-network-services

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.network-services.zone_id
  name            = "workspace-new-mfa.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "A"

  alias {
    name                   = aws_lb.radius_portal.dns_name
    zone_id                = aws_lb.radius_portal.zone_id
    evaluate_target_health = true
  }
}
