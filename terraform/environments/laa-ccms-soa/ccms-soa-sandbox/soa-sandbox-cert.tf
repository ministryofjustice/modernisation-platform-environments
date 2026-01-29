# #-- ACM Certificate for SOASANDBOX Load Balancers --#
# resource "aws_acm_certificate" "soa" {
#   domain_name               = trim(data.aws_route53_zone.external.name, ".")
#   subject_alternative_names = [aws_route53_record.admin.fqdn, aws_route53_record.managed.fqdn]
#   validation_method         = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "soa" {
#   certificate_arn         = aws_acm_certificate.soa.arn
#   validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
# }
