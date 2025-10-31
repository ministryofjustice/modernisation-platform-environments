## Certificates
#   *.laa-development.modernisation-platform.service.justice.gov.uk
#   *.laa-test.modernisation-platform.service.justice.gov.uk
#   *.laa-preproduction.modernisation-platform.service.justice.gov.uk

resource "aws_acm_certificate" "external" {

  validation_method = "DNS"
  domain_name       = format("%s-%s.modernisation-platform.service.justice.gov.uk", "laa", local.environment)
  subject_alternative_names = [
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "ccms-edrms", var.networking[0].business-unit, local.environment)
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

## Validation 
resource "aws_route53_record" "external_validation" {

  provider = aws.core-vpc

  for_each = {
    for dvo in local.cert_opts : dvo.domain_name => {
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
  zone_id         = local.cert_zone_id
}

resource "aws_acm_certificate_validation" "external" {

  depends_on = [
    aws_route53_record.external_validation
  ]

  certificate_arn         = local.cert_arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
