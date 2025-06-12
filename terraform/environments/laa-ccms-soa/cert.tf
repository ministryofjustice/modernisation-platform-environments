resource "aws_acm_certificate" "admin" {
  provider          = aws.core-vpc
  domain_name       = aws_route53_record.admin.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "managed" {
  provider          = aws.core-vpc
  domain_name       = aws_route53_record.managed.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
