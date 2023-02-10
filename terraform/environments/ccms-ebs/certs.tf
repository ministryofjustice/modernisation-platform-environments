/*
ccms-ebs.laa-development.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-test.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-preproduction.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-production.modernisation-platform.service.justice.gov.uk
*/

resource "aws_acm_certificate" "external" {
  count             = local.is-production ? 0 : 1
  domain_name       = "*.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"
  #subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external-validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.external[0].domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "external-validation" {
  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-validation : record.fqdn]
}



/*
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
  certificate_arn         = aws_acm_certificate.external-service[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-service-validation : record.fqdn]
}
*/
/*
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
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


resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}
*/
/*
resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
*/