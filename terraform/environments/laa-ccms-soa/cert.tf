resource "aws_acm_certificate" "soa" {
  domain_name               = data.aws_route53_zone.external.name
  subject_alternative_names = [aws_route53_record.admin.fqdn, aws_route53_record.admin.fqdn]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
