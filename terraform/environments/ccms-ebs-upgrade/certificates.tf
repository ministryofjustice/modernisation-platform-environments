## Certificates
#   *.laa-development.modernisation-platform.service.justice.gov.uk
#   *.laa-test.modernisation-platform.service.justice.gov.uk
#   *.laa-preproduction.modernisation-platform.service.justice.gov.uk

# resource "aws_acm_certificate" "laa_cert" {
#   domain_name       = format("%s-%s.modernisation-platform.service.justice.gov.uk", "laa", local.environment)
#   validation_method = "DNS"

#   subject_alternative_names = [
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "agatedev1-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "agatedev2-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "ccms-ebs-app1-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "ccms-ebs-app2-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "ccms-ebs-db-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "ccms-ebs-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "clamav-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "portal-ag-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "wgatedev1-upgrade", var.networking[0].business-unit, local.environment),
#     format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", "wgatedev2-upgrade", var.networking[0].business-unit, local.environment)
#   ]

#   tags = merge(local.tags,
#     { Name = lower(format("%s-%s-certificate", local.application_name, local.environment)) }
#   )

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "laa_cert" {
#   certificate_arn         = aws_acm_certificate.laa_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.laa_cert_validation : record.fqdn]
#   timeouts {
#     create = "10m"
#   }
# }

# resource "aws_route53_record" "laa_cert_validation" {
#   provider = aws.core-vpc
#   for_each = {
#     for dvo in aws_acm_certificate.laa_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.external.zone_id
# }
