## Certs
#   *.laa-development.modernisation-platform.service.justice.gov.uk
resource "aws_acm_certificate" "external" {
  count = local.is-production ? 0 : 1

  validation_method = "DNS"
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#   *.service.justice.gov.uk
resource "aws_acm_certificate" "external-service" {
  count = local.is-production ? 1 : 0

  validation_method = "DNS"
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = [
    "*.${var.networking[0].business-unit}.service.justice.gov.uk"
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

  provider  = aws.core-network-services

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
  zone_id   = data.aws_route53_zone.network-services.zone_id
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
