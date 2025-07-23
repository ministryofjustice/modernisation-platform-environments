resource "aws_route53_record" "ebsdbnlb" {
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