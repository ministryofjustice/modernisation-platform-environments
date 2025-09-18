# DNS Configuration

# Creates Route53 DNS records for the PUI LB in Non-Prod
resource "aws_route53_record" "route53_record_pui_nonprod" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_name
  type     = "A"

  alias {
    name                   = aws_lb.pui.dns_name
    zone_id                = aws_lb.pui.zone_id
    evaluate_target_health = false
  }
}


# Creates Route53 DNS records for the PUI LB in PROD
resource "aws_route53_record" "route53_record_pui_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.legalservices.zone_id
  name     = local.application_name
  type     = "A"
  alias {
    name                   = aws_lb.pui.dns_name
    zone_id                = aws_lb.pui.zone_id
    evaluate_target_health = false
  }
}