resource "aws_acm_certificate" "tipstaff_app_cert" {
  domain_name       = "modernisation-platform.internal"
  validation_method = "DNS"

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Points domain to load balancer
resource "aws_route53_record" "tipstaff_app_direct_traffic" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = "${local.application_data.accounts[local.environment].subdomain_name}.modernisation-platform.internal"
  records         = [aws_lb.tipstaff_dev_lb.dns_name]
  ttl             = 900
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.inner.zone_id
}


# resource "aws_route53_record" "internal_validation_tipstaff" {
#   provider = aws.core-network-services

#   allow_overwrite = true
#   name            = local.tipstaff_domain_name_main[0]
#   records         = local.tipstaff_domain_record_main
#   ttl             = 60
#   type            = local.tipstaff_domain_type_main[0]
#   zone_id         = data.aws_route53_zone.network-services.zone_id
# }

resource "aws_route53_record" "internal_validation_subdomain_tipstaff" {
  count    = length(local.tipstaff_domain_name_sub)
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.tipstaff_domain_name_sub[count.index]
  records         = [local.tipstaff_domain_record_sub[count.index]]
  ttl             = 60
  type            = local.tipstaff_domain_type_sub[count.index]
  zone_id         = data.aws_route53_zone.inner.zone_id
}

// validates the ACM Certificate by creating a record in Route53
# resource "aws_route53_record" "internal_validation_subdomain_tipstaff" {
#   provider = aws.core-vpc

#   for_each = {
#     for dvo in aws_acm_certificate.tipstaff_app_cert.domain_validation_options : dvo.domain_name => {
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
#   zone_id         = data.aws_route53_zone.inner.zone_id
# }

resource "aws_acm_certificate_validation" "tipstaff_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.tipstaff_app_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.internal_validation_subdomain_tipstaff : record.fqdn]
}
