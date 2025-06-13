resource "aws_acm_certificate" "soa" {
  domain_name               = trim(data.aws_route53_zone.external.name, ".") #--Remove the trailing dot from the zone name
  subject_alternative_names = [aws_route53_record.admin.fqdn, aws_route53_record.admin.fqdn]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
