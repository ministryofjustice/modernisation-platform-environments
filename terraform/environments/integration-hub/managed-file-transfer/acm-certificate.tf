/*  Because this approach uses two providers it's not a candidate for refactoring using a registry module */

resource "aws_acm_certificate" "ftps" {
  domain_name       = local.is-production == false ? "ftps.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "ftps.managed-file-transfer.service.justice.gov.uk"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }
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

  zone_id         = module.r53_managed_file_transfer.id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}