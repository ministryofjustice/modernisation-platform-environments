locals {
  cluster_base_domain = {
    "development_cluster" = "development.container-platform.service.justice.gov.uk"
    "preproduction"       = "nonlive.container-platform.service.justice.gov.uk"
    "production"          = "live.container-platform.service.justice.gov.uk"
  }[local.cluster_environment]
}

data "aws_route53_zone" "cluster_zone" {
  name  = local.cluster_base_domain
}

resource "aws_acm_certificate" "cluster_wildcard" {

  domain_name               = local.cluster_base_domain
  subject_alternative_names = ["*.${local.cluster_name}.${local.cluster_base_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cluster_wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cluster_wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.cluster_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cluster_wildcard" {
  certificate_arn         = aws_acm_certificate.cluster_wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.cluster_wildcard_validation : record.fqdn]
}
