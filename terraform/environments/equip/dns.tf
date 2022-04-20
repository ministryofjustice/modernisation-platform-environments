data "aws_route53_zone" "external_awsdns_zone" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

module "wildcard_cert" {
  source  = "./acm-dns"

  zone_id                   = data.aws_route53_zone.external_awsdns_zone.id
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = [
    "equip.hmpps-development.modernisation-platform.service.justice.gov.uk",
    "www.equip.hmpps-development.modernisation-platform.service.justice.gov.uk"
  ]
}
