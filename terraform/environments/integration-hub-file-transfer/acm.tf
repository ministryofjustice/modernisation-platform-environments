/*  Because this approach uses two providers it's not a candidate for refactoring using a registry module */
data "aws_route53_zone" "service" {
  provider     = aws.core-network-services
  name         = local.is-production == false ? "${local.environment}.file-transfer.service.justice.gov.uk" : "file-transfer.service.justice.gov.uk"
  private_zone = false
}

resource "aws_acm_certificate" "ftps" {
  domain_name       = local.is-production == false ? "ftps.${local.environment}.file-transfer.service.justice.gov.uk" : "ftps.file-transfer.service.justice.gov.uk"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ftps" {
  certificate_arn         = aws_acm_certificate.ftps.arn
  validation_record_fqdns = [for record in aws_route53_record.ftps_cert_validation : record.fqdn]
}

resource "aws_route53_record" "ftps_cert_validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.ftps.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = module.r53_file_transfer.id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}