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
      port        = 49100
    },
    "ahmlr" = {
      name_prefix = "landregistrationdivision"
      module_key  = "ahmlr"
      port        = 49101
    }
    "care_standards" = {
      name_prefix = "carestandards"
      module_key  = "care_standards"
      port        = 49102
    },
    "cicap" = {
      name_prefix = "cicap"
      module_key  = "cicap"
      port        = 49103
    },
    "employment_appeals" = {
      name_prefix = "employmentappeals"
      module_key  = "employment_appeals"
      port        = 49104
    },
    "finance_and_tax" = {
      name_prefix = "financeandtax"
      module_key  = "finance_and_tax"
      port        = 49105
    },
    "immigration_services" = {
      name_prefix = "immigrationservices"
      module_key  = "immigration_services"
      port        = 49106
    },
    "information_tribunal" = {
      name_prefix = "informationrights"
      module_key  = "information_tribunal"
      port        = 49107
    },
    "lands_tribunal" = {
      name_prefix = "landschamber"
      module_key  = "lands_tribunal"
      port        = 49108
    },
    "transport" = {
      name_prefix = "transportappeals"
      module_key  = "transport"
      port        = 49109
    },
    "charity_tribunal_decisions" = {
      name_prefix = "charitytribunal"
      module_key  = "charity_tribunal_decisions"
      port        = 49110
    },
    "claims_management_decisions" = {
      name_prefix = "claimsmanagement"
      module_key  = "claims_management_decisions"
      port        = 49111
    },
    "consumer_credit_appeals" = {
      name_prefix = "consumercreditappeals"
      module_key  = "consumer_credit_appeals"
      port        = 49112
    },
    "estate_agent_appeals" = {
      name_prefix = "estateagentappeals"
      module_key  = "estate_agent_appeals"
      port        = 49113
    },
    "primary_health_lists" = {
      name_prefix = "primaryhealthlists"
      module_key  = "primary_health_lists"
      port        = 49114
    },
    "siac" = {
      name_prefix = "siac"
      module_key  = "siac"
      port        = 49115
    },
    "sscs_venue_pages" = {
      name_prefix = "sscsvenues"
      module_key  = "sscs_venue_pages"
      port        = 49116
    },
    "tax_chancery_decisions" = {
      name_prefix = "taxchancerydecisions"
      module_key  = "tax_chancery_decisions"
      port        = 49117
    },
    "tax_tribunal_decisions" = {
      name_prefix = "taxtribunaldecisions"
      module_key  = "tax_tribunal_decisions"
      port        = 49118
    },
    "ftp_admin_appeals" = {
      name_prefix = "adminappealsreports"
      module_key  = "ftp_admin_appeals"
      port        = 49119
    }
  }
}

variable "web_app_services" {
  default = {
    "appeals" = {
      name_prefix         = "administrativeappeals"
      module_key          = "appeals"
      port                = 49100
      app_db_name         = "ossc"
      sql_setup_path      = "/db_setup_scripts/administrative_appeals"
      sql_post_setup_path = "/db_post_setup_scripts/administrative_appeals"
    },
    "ahmlr" = {
      name_prefix         = "landregistrationdivision"
      module_key          = "ahmlr"
      port                = 49101
      app_db_name         = "hmlands"
      sql_setup_path      = "/db_setup_scripts/ahmlr"
      sql_post_setup_path = "/db_post_setup_scripts/ahmlr"
    }
    "care_standards" = {
      name_prefix         = "carestandards"
      module_key          = "care_standards"
      port                = 49102
      app_db_name         = "carestandards"
      sql_setup_path      = "/db_setup_scripts/care_standards"
      sql_post_setup_path = "/db_post_setup_scripts/care_standards"
    },
    "cicap" = {
      name_prefix         = "cicap"
      module_key          = "cicap"
      port                = 49103
      app_db_name         = "cicap"
      sql_setup_path      = "/db_setup_scripts/cicap"
      sql_post_setup_path = "/db_post_setup_scripts/cicap"
    },
    "employment_appeals" = {
      name_prefix         = "employmentappeals"
      module_key          = "employment_appeals"
      port                = 49104
      app_db_name         = "eat"
      sql_setup_path      = "/db_setup_scripts/employment_appeals"
      sql_post_setup_path = "/db_post_setup_scripts/employment_appeals"
    },
    "finance_and_tax" = {
      name_prefix         = "financeandtax"
      module_key          = "finance_and_tax"
      port                = 49105
      app_db_name         = "ftt"
      sql_setup_path      = "/db_setup_scripts/finance_and_tax"
      sql_post_setup_path = "/db_post_setup_scripts/finance_and_tax"
    },
    "immigration_services" = {
      name_prefix         = "immigrationservices"
      module_key          = "immigration_services"
      port                = 49106
      app_db_name         = "imset"
      sql_setup_path      = "/db_setup_scripts/immigration_services"
      sql_post_setup_path = "/db_post_setup_scripts/immigration_services"
    },
    "information_tribunal" = {
      name_prefix         = "informationrights"
      module_key          = "information_tribunal"
      port                = 49107
      app_db_name         = "it"
      sql_setup_path      = "/db_setup_scripts/information_tribunal"
      sql_post_setup_path = "/db_post_setup_scripts/information_tribunal"
    },
    "lands_tribunal" = {
      name_prefix         = "landschamber"
      module_key          = "lands_tribunal"
      port                = 49108
      app_db_name         = "lands"
      sql_setup_path      = "/db_setup_scripts/lands_chamber"
      sql_post_setup_path = "/db_post_setup_scripts/lands_chamber"
    },
    "transport" = {
      name_prefix         = "transportappeals"
      module_key          = "transport"
      port                = 49109
      app_db_name         = "transport"
      sql_setup_path      = "/db_setup_scripts/transport"
      sql_post_setup_path = "/db_post_setup_scripts/transport"
    }
  }
}

variable "sftp_services" {
  default = {
    "charity_tribunal_decisions" = {
      name_prefix = "charitytribunal"
      module_key  = "charity_tribunal_decisions"
      sftp_port   = 10022
    },
    "claims_management_decisions" = {
      name_prefix = "claimsmanagement"
      module_key  = "claims_management_decisions"
      sftp_port   = 10023
    },
    "consumer_credit_appeals" = {
      name_prefix = "consumercreditappeals"
      module_key  = "consumer_credit_appeals"
      sftp_port   = 10024
    },
    "estate_agent_appeals" = {
      name_prefix = "estateagentappeals"
      module_key  = "estate_agent_appeals"
      sftp_port   = 10025
    },
    "primary_health_lists" = {
      name_prefix = "primaryhealthlists"
      module_key  = "primary_health_lists"
      sftp_port   = 10026
    },
    "siac" = {
      name_prefix = "siac"
      module_key  = "siac"
      sftp_port   = 10027
    },
    "sscs_venue_pages" = {
      name_prefix = "sscsvenues"
      module_key  = "sscs_venue_pages"
      sftp_port   = 10028
    },
    "tax_chancery_decisions" = {
      name_prefix = "taxchancerydecisions"
      module_key  = "tax_chancery_decisions"
      sftp_port   = 10029
    },
    "tax_tribunal_decisions" = {
      name_prefix = "taxtribunaldecisions"
      module_key  = "tax_tribunal_decisions"
      sftp_port   = 10030
    },
    "ftp_admin_appeals" = {
      name_prefix = "adminappealsreports"
      module_key  = "ftp_admin_appeals"
      sftp_port   = 10031
    }
  }
}

locals {
  modules = {
    appeals                     = module.appeals
    ahmlr                       = module.ahmlr
    care_standards              = module.care_standards
    cicap                       = module.cicap
    employment_appeals          = module.employment_appeals
    finance_and_tax             = module.finance_and_tax
    immigration_services        = module.immigration_services
    information_tribunal        = module.information_tribunal
    lands_tribunal              = module.lands_tribunal
    transport                   = module.transport
    charity_tribunal_decisions  = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
    consumer_credit_appeals     = module.consumer_credit_appeals
    estate_agent_appeals        = module.estate_agent_appeals
    primary_health_lists        = module.primary_health_lists
    siac                        = module.siac
    sscs_venue_pages            = module.sscs_venue_pages
    tax_chancery_decisions      = module.tax_chancery_decisions
    tax_tribunal_decisions      = module.tax_tribunal_decisions
    ftp_admin_appeals           = module.ftp_admin_appeals
  }
  sftp_modules = {
    charity_tribunal_decisions  = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
    consumer_credit_appeals     = module.consumer_credit_appeals
    estate_agent_appeals        = module.estate_agent_appeals
    primary_health_lists        = module.primary_health_lists
    siac                        = module.siac
    sscs_venue_pages            = module.sscs_venue_pages
    tax_chancery_decisions      = module.tax_chancery_decisions
    tax_tribunal_decisions      = module.tax_tribunal_decisions
    ftp_admin_appeals           = module.ftp_admin_appeals
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
    name                   = aws_lb.tribunals_lb.dns_name
    zone_id                = aws_lb.tribunals_lb.zone_id
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
  records         = [aws_lb.tribunals_lb_sftp.dns_name]
  ttl             = 60
}
