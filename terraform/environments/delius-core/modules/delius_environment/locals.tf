locals {
  tags = merge(
    var.tags,
    {
      delius-environment = var.env_name
    },
  )

  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  certificate_arn = aws_acm_certificate.external.arn

  moj_ips = concat(module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public, module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal, module.ip_addresses.moj_cidrs.trusted_mojo_public)
  unilink_ips = [
    "78.33.10.48/28",    # Unilink AOVPN (CF)
    "78.33.32.96/28",    # Unilink AOVPN (CF)
    "83.98.63.176/29",   # Unilink AOVPN (Newcastle)
    "80.209.165.232/32", # Unilink AOVPN (Newcastle)
    "217.138.45.109/32", # Unilink AOVPN (London)
    "217.138.45.110/32", # Unilink AOVPN (London)
  ]
  all_ingress_ips = concat(local.moj_ips, local.unilink_ips)

  secret_prefix           = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}"
  application_secret_name = "${local.secret_prefix}-application-passwords"
  mis_account_id          = var.platform_vars.environment_management.account_ids[join("-", ["delius-mis", var.account_info.mp_environment])]

  has_mis_environment = lookup(var.environment_config, "has_mis_environment", false)
}
