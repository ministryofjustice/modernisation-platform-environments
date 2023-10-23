locals {
  
  transport_url = "transportappeals"
  appeals_url = "administrativeappeals" 
}
  
resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

// Route53 DNS records for certificate validation
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

resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "${local.transport_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}


########## Transport Tribunals ###################

// ACM Public Certificate
# resource "aws_acm_certificate" "transport_external" {
#   domain_name       = "modernisation-platform.service.justice.gov.uk"
#   validation_method = "DNS"

#   subject_alternative_names = ["${local.transport_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
#   tags = {
#     Environment = local.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

// Route53 DNS record for directing traffic to the service
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.transport_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tribunals_lb.dns_name
    zone_id                = aws_lb.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

########## Administrative Appeals ###################

// ACM Public Certificate
# resource "aws_acm_certificate" "appeals_external" {
#   domain_name       = "modernisation-platform.service.justice.gov.uk"
#   validation_method = "DNS"

#   subject_alternative_names = ["${local.appeals_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
#   tags = {
#     Environment = local.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

// Route53 DNS record for directing traffic to the service
# resource "aws_route53_record" "appeals_external" {
#   provider = aws.core-vpc

#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "${local.appeals_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = aws_lb.tribunals_lb.dns_name
#     zone_id                = aws_lb.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }
