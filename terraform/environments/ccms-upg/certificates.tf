resource "aws_acm_certificate" "wildcard" {
  validation_method = "DNS"
  domain_name       = "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  tags = merge(local.tags, {
    Name = "${var.networking[0].business-unit}-${local.environment}-wildcard-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard_cert_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "wildcard" {
  depends_on              = [aws_route53_record.wildcard_cert_validation]
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
