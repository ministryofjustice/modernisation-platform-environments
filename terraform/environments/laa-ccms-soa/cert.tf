resource "aws_acm_certificate" "admin" {
  domain_name               = aws_route53_record.admin.fqdn
  certificate_authority_arn = local.application_data.accounts[local.environment].certificate_authority_arn
  validation_method         = "NONE"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "managed" {
  domain_name               = aws_route53_record.managed.fqdn
  certificate_authority_arn = local.application_data.accounts[local.environment].certificate_authority_arn
  validation_method         = "NONE"
  lifecycle {
    create_before_destroy = true
  }
}
