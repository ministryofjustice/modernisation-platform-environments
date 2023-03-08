# resource "aws_acm_certificate" "tipstaff_app_cert" {
#   domain_name       = "modernisation-platform.service.justice.gov.uk"
#   validation_method = "DNS"
#   tags = {
#     Environment = local.environment
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "external_validation_tipstaff" {
#   provider        = aws.core-network-services
#   allow_overwrite = true
#   name            = local.tipstaff_domain_name_main[0]
#   records         = local.tipstaff_domain_record_main
#   ttl             = 60
#   type            = local.tipstaff_domain_type_main[0]
#   zone_id         = data.aws_route53_zone.network-services.zone_id
# }

# resource "aws_route53_record" "external_validation_subdomain_tipstaff" {
#   count           = length(local.tipstaff_domain_name_sub)
#   provider        = aws.core-vpc
#   allow_overwrite = true
#   name            = local.tipstaff_domain_name_sub[count.index]
#   records         = [local.tipstaff_domain_record_sub[count.index]]
#   ttl             = 60
#   type            = local.tipstaff_domain_type_sub[count.index]
#   zone_id         = data.aws_route53_zone.external.zone_id
# }

# resource "aws_acm_certificate_validation" "tipstaff_lb_cert_validation" {
#   certificate_arn         = aws_acm_certificate.tipstaff_app_cert.arn
#   validation_record_fqdns = [for record in local.tipstaff_domain_types : record.name]
# }

#------------------------------------------------------------------------------

resource "aws_route53_record" "inner" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.inner.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff_dev_lb.dns_name
    zone_id                = aws_lb.tipstaff_dev_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "inner" {
  domain_name               = "${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"
  validation_method         = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"]
  tags = {
    Environment = "test"
  }
  lifecycle {
    create_before_destroy = true
  }
}
