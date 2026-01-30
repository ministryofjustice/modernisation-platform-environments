# # #-- ACM Certificate for SOASANDBOX Load Balancers --#
# resource "aws_acm_certificate" "soa-sandbox" {
#   domain_name               = trim(data.aws_route53_zone.external.name, ".")
#   subject_alternative_names = [aws_route53_record.admin-sandbox.fqdn, aws_route53_record.managed-sandbox.fqdn]
#   validation_method         = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "soa-sandbox" {
#   certificate_arn         = aws_acm_certificate.soa-sandbox.arn
#   validation_record_fqdns = [for record in aws_route53_record.validation-sandbox : record.fqdn]
# }
