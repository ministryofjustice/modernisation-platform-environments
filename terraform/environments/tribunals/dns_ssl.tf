# // Create one Route 53 record for each entry in the list of tribunals (assigned in platform_locals.tf)
resource "aws_route53_record" "external_appeals" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "administrativeappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.appeals.tribunals_lb.dns_name
    zone_id                = module.appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_ahmlr" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "landregistrationdivision.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.ahmlr.tribunals_lb.dns_name
    zone_id                = module.ahmlr.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

# resource "aws_route53_record" "external_care_standards" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "carestandards.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.care_standards.tribunals_lb.dns_name
#     zone_id                = module.care_standards.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_cicap" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "cicap.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.cicap.tribunals_lb.dns_name
#     zone_id                = module.cicap.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_eat" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "employmentappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.employment_appeals.tribunals_lb.dns_name
#     zone_id                = module.employment_appeals.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_ftt" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "financeandtax.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.finance_and_tax.tribunals_lb.dns_name
#     zone_id                = module.finance_and_tax.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_imset" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "immigrationservices.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.immigration_services.tribunals_lb.dns_name
#     zone_id                = module.immigration_services.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_it" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "informationrights.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.information_tribunal.tribunals_lb.dns_name
#     zone_id                = module.information_tribunal.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_lands" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "landschamber.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.lands_tribunal.tribunals_lb.dns_name
#     zone_id                = module.lands_tribunal.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "external_transport" {
#   provider = aws.core-vpc
#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "transportappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = module.transport.tribunals_lb.dns_name
#     zone_id                = module.transport.tribunals_lb.zone_id
#     evaluate_target_health = true
#   }
# }

// Records for FTP sites
resource "aws_route53_record" "external_charity" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "charitytribunal.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.charity_tribunal_decisions.tribunals_lb.dns_name
    zone_id                = module.charity_tribunal_decisions.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_charity_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.charitytribunal.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.charity_tribunal_decisions.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_claims_management" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "claimsmanagement.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.claims_management_decisions.tribunals_lb.dns_name
    zone_id                = module.claims_management_decisions.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_claims_management_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.claimsmanagement.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.claims_management_decisions.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_consumer_credit_appeals" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "consumercreditappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.consumer_credit_appeals.tribunals_lb.dns_name
    zone_id                = module.consumer_credit_appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_consumer_credit_appeals_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.consumercreditappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.consumer_credit_appeals.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_estate_agent_appeals" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "estateagentappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.estate_agent_appeals.tribunals_lb.dns_name
    zone_id                = module.estate_agent_appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_estate_agent_appeals_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.estateagentappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.estate_agent_appeals.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_primary_health_lists" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "primaryhealthlists.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.primary_health_lists.tribunals_lb.dns_name
    zone_id                = module.primary_health_lists.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_primary_health_lists_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.primaryhealthlists.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.primary_health_lists.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_siac" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "siac.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.siac.tribunals_lb.dns_name
    zone_id                = module.siac.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_siac_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.siac.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.siac.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_sscs_venue_pages" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "sscsvenues.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.sscs_venue_pages.tribunals_lb.dns_name
    zone_id                = module.sscs_venue_pages.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_sscs_venue_pages_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.sscsvenues.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.sscs_venue_pages.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_tax_chancery_decisions" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "taxchancerydecisions.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.tax_chancery_decisions.tribunals_lb.dns_name
    zone_id                = module.tax_chancery_decisions.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_tax_chancery_decisions_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.taxchancerydecisions.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.tax_chancery_decisions.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_tax_tribunal_decisions" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "taxtribunaldecisions.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.tax_tribunal_decisions.tribunals_lb.dns_name
    zone_id                = module.tax_tribunal_decisions.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_tax_tribunal_decisions_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.taxtribunaldecisions.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.tax_tribunal_decisions.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}

resource "aws_route53_record" "external_ftp_admin_appeals" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "adminappealsreports.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.ftp-admin-appeals.tribunals_lb.dns_name
    zone_id                = module.ftp-admin-appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_admin_appeals_sftp" {
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.adminappealsreports.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"

  records         = [module.ftp-admin-appeals.tribunals_lb_ftp[0].dns_name]
  ttl             = 60
}


# ACM certificate validation
resource "aws_acm_certificate_validation" "external" {
  certificate_arn = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

# One route53 record required for each domain listed in the external certificate
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

# Define a wildcard ACM certificate for sandbox/dev
resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.external.arn
}

output "acm_certificate_validation_dns" {
  value = [for dvo in aws_acm_certificate.external.domain_validation_options : dvo.resource_record_name]
}

output "acm_certificate_validation_route53" {
  value = [for dvo in aws_acm_certificate.external.domain_validation_options : dvo.resource_record_value]
}