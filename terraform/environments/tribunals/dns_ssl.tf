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
    "care_standards" = {
      name_prefix = "carestandards"
      module_key  = "care_standards"
    },
    "cicap" = {
      name_prefix = "cicap"
      module_key  = "cicap"
    },
    "employment_appeals" = {
      name_prefix = "employmentappeals"
      module_key  = "employment_appeals"
    },
    "finance_and_tax" = {
      name_prefix = "financeandtax"
      module_key  = "finance_and_tax"
    },
    "immigration_services" = {
      name_prefix = "immigrationservices"
      module_key  = "immigration_services"
    },
    "information_tribunal" = {
      name_prefix = "informationrights"
      module_key  = "information_tribunal"
    },

    "charity_tribunal_decisions" = {
      name_prefix = "charitytribunal"
      module_key  = "charity_tribunal_decisions"
    },
    "claims_management_decisions" = {
      name_prefix = "claimsmanagement"
      module_key  = "claims_management_decisions"
    },
    "consumer_credit_appeals" = {
      name_prefix = "consumercreditappeals"
      module_key  = "consumer_credit_appeals"
    },
    "estate_agent_appeals" = {
      name_prefix = "estateagentappeals"
      module_key  = "estate_agent_appeals"
    },
    "primary_health_lists" = {
      name_prefix = "primaryhealthlists"
      module_key  = "primary_health_lists"
    },
    "siac" = {
      name_prefix = "siac"
      module_key  = "siac"
    },
    "sscs_venue_pages" = {
      name_prefix = "sscsvenues"
      module_key  = "sscs_venue_pages"
    },
    "tax_chancery_decisions" = {
      name_prefix = "taxchancerydecisions"
      module_key  = "tax_chancery_decisions"
    },
    "tax_tribunal_decisions" = {
      name_prefix = "taxtribunaldecisions"
      module_key  = "tax_tribunal_decisions"
    },
    "ftp_admin_appeals" = {
      name_prefix = "adminappealsreports"
      module_key  = "ftp_admin_appeals"
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
    },
    "consumer_credit_appeals" = {
      name_prefix = "consumercreditappeals"
      module_key  = "consumer_credit_appeals"
    },
    "estate_agent_appeals" = {
      name_prefix = "estateagentappeals"
      module_key  = "estate_agent_appeals"
    },
    "primary_health_lists" = {
      name_prefix = "primaryhealthlists"
      module_key  = "primary_health_lists"
    },
    "siac" = {
      name_prefix = "siac"
      module_key  = "siac"
    },
    "sscs_venue_pages" = {
      name_prefix = "sscsvenues"
      module_key  = "sscs_venue_pages"
    },
    "tax_chancery_decisions" = {
      name_prefix = "taxchancerydecisions"
      module_key  = "tax_chancery_decisions"
    },
    "tax_tribunal_decisions" = {
      name_prefix = "taxtribunaldecisions"
      module_key  = "tax_tribunal_decisions"
    },
    "ftp_admin_appeals" = {
      name_prefix = "adminappealsreports"
      module_key  = "ftp_admin_appeals"
    }
  }
}

locals {
  modules = {
    appeals = module.appeals
    ahmlr = module.ahmlr
    care_standards = module.care_standards
    cicap = module.cicap
    employment_appeals = module.employment_appeals
    finance_and_tax = module.finance_and_tax
    immigration_services = module.immigration_services
    information_tribunal = module.information_tribunal
    charity_tribunal_decisions = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
    consumer_credit_appeals = module.consumer_credit_appeals
    estate_agent_appeals = module.estate_agent_appeals
    primary_health_lists = module.primary_health_lists
    siac = module.siac
    sscs_venue_pages = module.sscs_venue_pages
    tax_chancery_decisions = module.tax_chancery_decisions
    tax_tribunal_decisions = module.tax_tribunal_decisions
    ftp_admin_appeals = module.ftp_admin_appeals
  }
  sftp_modules = {
    charity_tribunal_decisions = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
    consumer_credit_appeals = module.consumer_credit_appeals
    estate_agent_appeals = module.estate_agent_appeals
    primary_health_lists = module.primary_health_lists
    siac = module.siac
    sscs_venue_pages = module.sscs_venue_pages
    tax_chancery_decisions = module.tax_chancery_decisions
    tax_tribunal_decisions = module.tax_tribunal_decisions
    ftp_admin_appeals = module.ftp_admin_appeals
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
