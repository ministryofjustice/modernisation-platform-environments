# ACM Certificate for OIA
# Separate validation zones for NonProd and Prod environments

resource "aws_acm_certificate" "oia" {
  domain_name               = "${local.application_name}.${var.networking[0].business-unit}.modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"

  subject_alternative_names = [
    "*.${local.application_name}.${var.networking[0].business-unit}.modernisation-platform.service.justice.gov.uk"
  ]

  tags = merge(local.tags, {
    Environment = local.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation Records (NonProd or Prod zone based on env)
resource "aws_route53_record" "oia_cert_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in aws_acm_certificate.oia.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "oia" {
  certificate_arn         = aws_acm_certificate.oia.arn
  validation_record_fqdns = [for record in aws_route53_record.oia_cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
