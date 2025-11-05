resource "aws_acm_certificate" "external" {
  domain_name               = local.is-production ? "*.decisions.tribunals.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = local.is-production ? local.common_sans : local.nonprod_sans
  key_algorithm             = "RSA_2048"

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

// Route53 DNS records for certificate validation
resource "aws_route53_record" "cert_validation" {
  provider = aws.core-network-services

  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 300
  type            = each.value.type
  zone_id         = local.is-production ? data.aws_route53_zone.production_zone.zone_id : data.aws_route53_zone.network-services.zone_id
}

// sub-domain validation only required for non-production sites
resource "aws_route53_record" "external_validation_subdomain" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
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
    asylum_support              = module.asylum_support
    charity_tribunal_decisions  = module.charity_tribunal_decisions
    claims_management_decisions = module.claims_management_decisions
    consumer_credit_appeals     = module.consumer_credit_appeals
    estate_agent_appeals        = module.estate_agent_appeals
    primary_health_lists        = module.primary_health_lists
    siac                        = module.siac
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
    tax_chancery_decisions      = module.tax_chancery_decisions
    tax_tribunal_decisions      = module.tax_tribunal_decisions
    ftp_admin_appeals           = module.ftp_admin_appeals
  }
}

// Create one Route 53 record for each entry in the services variable list of tribunals
resource "aws_route53_record" "external_services" {
  for_each = local.is-production ? {} : var.services
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${each.value.name_prefix}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.tribunals_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.tribunals_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sftp_external_services" {
  for_each        = local.is-production ? {} : var.sftp_services
  allow_overwrite = true
  provider        = aws.core-vpc
  zone_id         = data.aws_route53_zone.external.zone_id
  name            = "sftp.${each.value.name_prefix}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type            = "CNAME"
  records         = [aws_lb.tribunals_lb_sftp.dns_name]
  ttl             = 60
}