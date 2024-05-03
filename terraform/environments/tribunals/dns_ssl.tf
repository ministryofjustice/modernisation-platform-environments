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

resource "aws_route53_record" "external_care_standards" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "carestandards.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.care_standards.tribunals_lb.dns_name
    zone_id                = module.care_standards.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_cicap" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "cicap.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.cicap.tribunals_lb.dns_name
    zone_id                = module.cicap.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_eat" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "employmentappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.employment_appeals.tribunals_lb.dns_name
    zone_id                = module.employment_appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_ftt" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "financeandtax.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.finance_and_tax.tribunals_lb.dns_name
    zone_id                = module.finance_and_tax.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_imset" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "immigrationservices.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.immigration_services.tribunals_lb.dns_name
    zone_id                = module.immigration_services.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_it" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "informationrights.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.information_tribunal.tribunals_lb.dns_name
    zone_id                = module.information_tribunal.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_lands" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "landschamber.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.lands_tribunal.tribunals_lb.dns_name
    zone_id                = module.lands_tribunal.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_transport" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "transportappeals.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.transport.tribunals_lb.dns_name
    zone_id                = module.transport.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

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
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "sftp.charitytribunal.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  records = [module.charity_tribunal_decisions.tribunals_lb_ftp[0].dns_name]
  ttl     = 60
}

# Define a wildcard ACM certificate for sandbox/dev
resource "aws_acm_certificate" "external" {
  domain_name       = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
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