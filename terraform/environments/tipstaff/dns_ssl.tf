// ACM Public Certificate
resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Route53 DNS record for directing traffic to the service 
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff_lb.dns_name
    zone_id                = aws_lb.tipstaff_lb.zone_id
    evaluate_target_health = true
  }
}

// Route53 DNS record for certificate validation
resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

# // PROD DNS

# // ACM Public Certificate
# resource "aws_acm_certificate" "external_prod" {
#   # count             = local.is-production ? 1 : 0
#   domain_name       = "tipstaff.service.justice.gov.uk"
#   validation_method = "DNS"
#   subject_alternative_names = [
#     "*.tipstaff.service.justice.gov.uk"
#   ]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# // Route53 DNS record for directing traffic to the service
# resource "aws_route53_record" "external_prod" {
#   # count    = local.is-production ? 1 : 0
#   provider = aws.core-network-services
#   zone_id  = data.aws_route53_zone.prod_network_services.zone_id
#   name     = "tipstaff.service.justice.gov.uk"
#   type     = "A"

#   alias {
#     name                   = aws_lb.tipstaff_lb.dns_name
#     zone_id                = aws_lb.tipstaff_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# // Route53 DNS record for certificate validation
# resource "aws_route53_record" "external_validation_prod" {
#   # count    = local.is-production ? 1 : 0
#   provider = aws.core-network-services

#   for_each = {
#     for dvo in aws_acm_certificate.external_prod.domain_validation_options : dvo.domain_name => {
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
#   zone_id         = data.aws_route53_zone.application_zone.zone_id
# }

# resource "aws_acm_certificate_validation" "external_prod" {
#   # count = local.is-production ? 1 : 0
#   depends_on = [
#     aws_route53_record.external_validation_prod
#   ]
#   certificate_arn         = aws_acm_certificate.external_prod.arn
#   validation_record_fqdns = [for record in aws_route53_record.external_validation_prod : record.fqdn]
#   timeouts {
#     create = "10m"
#   }
# }
