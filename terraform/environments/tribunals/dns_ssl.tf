// DEV + PRE-PRODUCTION DNS CONFIGURATION

// ACM Public Certificate
resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
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

variable "services" {
  default = {
    "appeals" = {
      name_prefix = "administrativeappeals"
      module_key  = "appeals"
    },
    "ahmlr" = {
      name_prefix = "landregistrationdivision"
      module_key  = "ahmlr"
    }
  }
}

variable "sftp_services" {
  default = {
    "charity_tribunal_decisions" = {
      name_prefix = "charitytribunal"
      module_key  = "charity_tribunal_decisions"
    },
    "claims_management_decisions" = {
      name_prefix = "claimsmanagement"
      module_key  = "claims_management_decisions"
    }
  }
}

locals {
  modules = {
    appeals = module.appeals
    ahmlr = module.ahmlr
  }
  sftp_modules = {
    charity_tribunal_decisions = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
  }
}

// Create one Route 53 record for each entry in the list of tribunals (assigned in platform_locals.tf)
resource "aws_route53_record" "external_services" {
  for_each = var.services
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${each.value.name_prefix}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = local.modules[each.value.module_key].tribunals_lb.dns_name
    zone_id                = local.modules[each.value.module_key].tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sftp_external_services" {
  for_each        = var.sftp_services
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.${each.value.name_prefix}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"
  records         = [local.sftp_modules[each.value.module_key].tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}
