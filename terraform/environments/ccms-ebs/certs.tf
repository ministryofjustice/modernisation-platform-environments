

################################################################
#   *.modernisation-platform.service.justice.gov.uk
################################################################
resource "aws_acm_certificate" "external-mp" {
  count             = local.is-production ? 0 : 1
  domain_name       = "*.modernisation-platform.service.justice.gov.uk"
  #domain_name       = "*.${local.application_data.accounts[local.environment].dns}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"
  #subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  #######  ccms-ebs.laa-development.modernisation-platform.service.justice.gov.uk
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
/*
################################################################
#   *.service.justice.gov.uk
################################################################

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

resource "aws_acm_certificate_validation" "external-servvice-validation" {
  depends_on = [
    aws_route53_record.external-service-validation
  ]
  certificate_arn         = aws_acm_certificate.external-service[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-service-validation : record.fqdn]
}
*/
