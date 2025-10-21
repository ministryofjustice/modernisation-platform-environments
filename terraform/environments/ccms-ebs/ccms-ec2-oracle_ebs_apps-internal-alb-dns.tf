# DNS Configuration

# Creates Route53 DNS records for the EBS Apps Internal ALB in Non-Prod
resource "aws_route53_record" "route53_record_ebsapps_internal_nonprod" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccmsebs"
  type     = "A"

  alias {
    name                   = aws_lb.ebsapps_internal_alb.dns_name
    zone_id                = aws_lb.ebsapps_internal_alb.zone_id
    evaluate_target_health = false
  }
}


# Creates Route53 DNS records for the EBS Apps Internal ALB in Prod
resource "aws_route53_record" "route53_record_ebsapps_internal_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.laa.zone_id
  name     = "ccmsebs"
  type     = "A"
  alias {
    name                   = aws_lb.ebsapps_internal_alb.dns_name
    zone_id                = aws_lb.ebsapps_internal_alb.zone_id
    evaluate_target_health = false
  }
}