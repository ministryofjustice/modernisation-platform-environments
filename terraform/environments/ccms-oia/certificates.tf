## Certificates
#   laa-<env>.modernisation-platform.service.justice.gov.uk
#   ccms-oia-<env>.modernisation-platform.service.justice.gov.uk

resource "aws_acm_certificate" "external" {
  domain_name               = format("laa-%s.modernisation-platform.service.justice.gov.uk", local.environment)
  validation_method         = "DNS"
  subject_alternative_names = [
    format("ccms-oia-%s.modernisation-platform.service.justice.gov.uk", local.environment)
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ACM
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.external.zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

# Certificate validation
resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
