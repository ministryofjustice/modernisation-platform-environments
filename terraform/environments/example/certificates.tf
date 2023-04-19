resource "aws_acm_certificate" "example_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    format("%s.%s.%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment),
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-certificate", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "example_cert" {
  certificate_arn         = aws_acm_certificate.example_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example_cert_validation : record.fqdn]
  timeouts {
    create = "10m"
  }
}

resource "aws_route53_record" "example_cert_validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.example_cert.domain_validation_options : dvo.domain_name => {
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