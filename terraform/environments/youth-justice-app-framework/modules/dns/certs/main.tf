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
  count = var.validate_certs ? length([
    for dvo in aws_acm_certificate.domain_cert.domain_validation_options : dvo
  ]) : 0

  allow_overwrite = true
  name            = aws_acm_certificate.domain_cert.domain_validation_options.resource_record_name
  records         = [aws_acm_certificate.domain_cert.domain_validation_options.resource_record_value]
  ttl             = 300
  type            = aws_acm_certificate.domain_cert.domain_validation_options.resource_record_type
  zone_id         = var.r53_zone_id
}




#Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "cert" {
  count                   = var.validate_certs ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.name]
}
