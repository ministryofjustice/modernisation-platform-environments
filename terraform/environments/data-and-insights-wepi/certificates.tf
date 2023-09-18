resource "aws_acm_certificate" "redshift_cert" {
  domain_name       = format("%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
  validation_method = "DNS"

  subject_alternative_names = [
    format("redshift.%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment),
  ]

  tags = merge(local.tags,
    { Name = lower(format("redshift.%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "redshift_cert" {
  certificate_arn         = aws_acm_certificate.redshift_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.redshift_cert_validation : record.fqdn]
  timeouts {
    create = "15m"
  }
}

resource "aws_route53_record" "redshift_cert_validation" {
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
  zone_id         = data.aws_route53_zone.network-services.zone_id
}
