# Creates Route53 DNS records for the EBS DB NLB in Non-Prod
resource "aws_route53_record" "ebsdbnlb" {
  # This count only be 1 in NonProd
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-db-nlb"
  type     = "A"
  alias {
    name                   = aws_lb.ebsdb_nlb.dns_name
    zone_id                = aws_lb.ebsdb_nlb.zone_id
    evaluate_target_health = false
  }
}

# Creates Route53 DNS records for the EBS DB NLB in PROD - required to match certificate
resource "aws_route53_record" "ebsdbnlb-prod" {
  # This count only be 1 in Prod
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.laa.zone_id
  name     = "ccms-ebs-db-nlb.laa.service.justice.gov.uk"
  type     = "A"
  alias {
    name                   = aws_lb.ebsdb_nlb.dns_name
    zone_id                = aws_lb.ebsdb_nlb.zone_id
    evaluate_target_health = false
  }
}