#Must create ns record in main hosted zone before running
#create a certificate in ACM
resource "aws_acm_certificate" "domain_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.validate_certs ? {
    for dvo in aws_acm_certificate.domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = var.r53_zone_id
}




#Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "cert" {
  count                   = var.validate_certs ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.name]
}
