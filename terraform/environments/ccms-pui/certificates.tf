## Certificates
#   *.laa-development.modernisation-platform.service.justice.gov.uk
#   *.laa-test.modernisation-platform.service.justice.gov.uk
#   *.laa-preproduction.modernisation-platform.service.justice.gov.uk
#   *.legalservices.gov.uk

# Certificate

resource "aws_acm_certificate" "external" {
  validation_method         = "DNS"
  domain_name               = local.primary_domain
  subject_alternative_names = local.subject_alternative_names

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

## Validation Records

resource "aws_route53_record" "external_validation_nonprod" {
  count    = local.is-production ? 0 : length(local.modernisation_platform_validations)
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.modernisation_platform_validations[count.index].name
  records         = [local.modernisation_platform_validations[count.index].record]
  ttl             = 60
  type            = local.modernisation_platform_validations[count.index].type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_route53_record" "external_validation_prod" {
  count    = local.is-production ? length(local.legalservices_validations) : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.legalservices_validations[count.index].name
  records         = [local.legalservices_validations[count.index].record]
  ttl             = 60
  type            = local.legalservices_validations[count.index].type
  zone_id         = data.aws_route53_zone.legalservices.zone_id
}

## Certificate Validation

resource "aws_acm_certificate_validation" "external_nonprod" {
  count = local.is-production ? 0 : 1

  depends_on = [
    aws_route53_record.external_validation_nonprod
  ]

  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_nonprod : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate_validation" "external_prod" {
  count = local.is-production ? 1 : 0

  depends_on = [
    aws_route53_record.external_validation_prod
  ]

  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_prod : record.fqdn]

  timeouts {
    create = "10m"
  }
}
