locals {
  lbs_prod_domain = local.environment == "production" ? "tbd.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"

  lbs_domain_types = { for dvo in aws_acm_certificate.load_balancer.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  lbs_domain_name_main   = [for k, v in local.lbs_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_name_sub    = [for k, v in local.lbs_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_record_main = [for k, v in local.lbs_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_record_sub  = [for k, v in local.lbs_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_type_main   = [for k, v in local.lbs_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_type_sub    = [for k, v in local.lbs_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

}

resource "aws_acm_certificate" "load_balancer" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = local.environment == "production" ? null : ["${local.application_name_short}.${data.aws_route53_zone.external.name}"]
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "load_balancer_external_validation" {
  provider = aws.core-network-services

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.lbs_domain_name_main[0]
  records         = local.lbs_domain_record_main
  ttl             = 60
  type            = local.lbs_domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "load_balancer_external_validation_subdomain_1" {
  provider = aws.core-vpc

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.lbs_domain_name_sub[0]
  records         = [local.lbs_domain_record_sub[0]]
  ttl             = 60
  type            = local.lbs_domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "load_balancer" {
  certificate_arn         = aws_acm_certificate.load_balancer.arn
  validation_record_fqdns = [local.lbs_domain_name_main[0], local.lbs_domain_name_sub[0]]
}