resource "aws_acm_certificate" "redshift_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    format("redshift.%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment),
  ]

  tags = merge(local.tags,
    { Name = lower(format("redshift.%s-%s-certificate", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "redshift_cert" {
  depends_on = [aws_route53_record.redshift_cert_validation_core, aws_route53_record.redshift_cert_validation_vpc]
  certificate_arn = aws_acm_certificate.redshift_cert.arn
  validation_record_fqdns = concat(
    [for record_core in aws_route53_record.redshift_cert_validation_core : record_core.fqdn],
    [for record_vpc in aws_route53_record.redshift_cert_validation_vpc : record_vpc.fqdn]
  )
  timeouts {
    create = "10m"
  }
}

# Because we need validation records in multiple zones, we'll call them twice with different providers
resource "aws_route53_record" "redshift_cert_validation_core" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.redshift_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "redshift_cert_validation_vpc" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.redshift_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.inner.zone_id
}