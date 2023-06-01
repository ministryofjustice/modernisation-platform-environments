locals {
  zone_name = "jitbit.dev.cr.probation.service.justice.gov.uk"
}


data "aws_route53_zone" "external_test" {
  provider = aws.core-network-services

  name         = local.zone_name
  private_zone = false
}




resource "aws_route53_record" "external_test" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external_test.zone_id
  name    = "helpdesk.${local.zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}
