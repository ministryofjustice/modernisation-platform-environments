resource "aws_route53_record" "external" {
  count    = local.is-production ? 1 : 1
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.app_url
  type    = "A"

  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = local.domain
  validation_method = "DNS"

  subject_alternative_names = local.acm_subject_alternative_names
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  count    = local.is-production ? 1 : 1
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = local.is-production ? 1 : 1
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
  validation_record_fqdns = local.validation_record_fqdns
}

# Internal ALB
resource "aws_route53_zone" "internal" {
  name = "victim-case-management.service.justice.gov.uk"

  vpc {
    vpc_id = local.account_info.vpc_id
  }

  tags = merge(local.tags, {
    Name = "victim-case-management-internal"
  })
}

resource "aws_route53_record" "internal_alb" {
  provider = aws.core-vpc

  zone_id = aws_route53_zone.internal.zone_id
  name    = "www.${local.environment_short}.victim-case-management.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.frontend_internal.dns_name
    zone_id                = aws_lb.frontend_internal.zone_id
    evaluate_target_health = true
  }
}

# resource "aws_route53_record" "internal" {
#   provider = aws.core-vpc

#   zone_id = local.account_config.route53_inner_zone.zone_id
#   name    = local.account_config.internal_dns_suffix
#   type    = "A"

#   alias {
#     name                   = aws_lb.frontend_internal.dns_name
#     zone_id                = aws_lb.frontend_internal.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_ssm_parameter" "internal_ca_arn" {
#   name        = "internal-ca-arn"
#   description = "ARN of the Private CA used for internal VCMS certificates"
#   type        = "String"
#   value       = "change_me"

#   lifecycle {
#     ignore_changes = [value]
#   }

#   tags = merge(local.tags, {
#     Name = "vcms-internal-ca-arn"
#   })
# }

resource "aws_acm_certificate" "internal" {
  domain_name               = "www.${local.environment_short}.victim-case-management.service.justice.gov.uk"
  certificate_authority_arn = data.aws_ssm_parameter.internal_ca_arn.value

  tags = merge(local.tags, {
    Name = "frontend-internal-https"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_acm_certificate" "internal" {
#   domain_name       = local.account_config.internal_dns_suffix
#   validation_method = "DNS"

#   tags = merge(local.tags, {
#     Name = "frontend-internal-https"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "internal_cert_validation" {
#   provider = aws.core-vpc

#   for_each = {
#     for dvo in aws_acm_certificate.internal.domain_validation_options :
#     dvo.domain_name => {
#       name   = dvo.resource_record_name
#       type   = dvo.resource_record_type
#       record = dvo.resource_record_value
#     }
#   }

#   zone_id = local.account_config.route53_inner_zone.zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.record]
#   ttl     = 60
# }

# resource "aws_acm_certificate_validation" "internal" {
#   provider = aws.core-vpc

#   certificate_arn = aws_acm_certificate.internal.arn

#   validation_record_fqdns = [
#     for record in aws_route53_record.internal_cert_validation :
#     record.fqdn
#   ]
# }