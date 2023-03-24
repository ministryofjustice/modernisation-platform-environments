###################################################
# *.modernisation-platform.service.justice.gov.uk #
###################################################
resource "aws_acm_certificate" "laa_cert" {
  domain_name       = format("x.%s-%s.modernisation-platform.service.justice.gov.uk", "laa", local.environment)
  validation_method = "DNS"

  subject_alternative_names = [
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "app", var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "db", var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "laa-oem-app", var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "laa-oem-db", var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "oem", var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "oem-ext", var.networking[0].business-unit, local.environment)
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-certificate", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "laa_cert" {
  certificate_arn         = aws_acm_certificate.laa_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.laa_cert_validation : record.fqdn]
  timeouts {
    create = "16m"
  }
}

resource "aws_route53_record" "laa_cert_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.laa_cert.domain_validation_options : dvo.domain_name => {
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

/*
resource "aws_acm_certificate" "external-mp" {
  count             = local.is-production ? 0 : 1
  domain_name       = "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"
  subject_alternative_names = [
    "app.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "laa-oem-app.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "laa-oem-db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "oem.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "oem-internal.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]
  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external-mp" {
  depends_on = [
    aws_acm_certificate.external-mp
  ]
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.external-mp[0].domain_validation_options : dvo.domain_name => {
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
  #zone_id         = data.aws_route53_zone.external.zone_id
  zone_id = data.aws_route53_zone.network-services.zone_id
}

resource "aws_acm_certificate_validation" "external-mp" {
  depends_on = [
    aws_route53_record.external-mp
  ]
  certificate_arn         = aws_acm_certificate.external-mp[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-mp : record.fqdn]
}

############################
# *.service.justice.gov.uk #
############################
resource "aws_acm_certificate" "external-service" {
  count             = local.is-production ? 0 : 1
  domain_name       = "*.service.justice.gov.uk"
  validation_method = "DNS"
  #subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external-service-validation" {
  depends_on = [
    aws_acm_certificate.external-service
  ]
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.external-service[0].domain_validation_options : dvo.domain_name => {
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
  #zone_id         = data.aws_route53_zone.external.zone_id
  zone_id = data.aws_route53_zone.network-services.zone_id
}

resource "aws_acm_certificate_validation" "external-service-validation" {
  depends_on = [
    aws_route53_record.external-service-validation
  ]
  certificate_arn         = aws_acm_certificate.external-service[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-service-validation : record.fqdn]
}
*/
