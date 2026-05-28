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
    "194.75.210.216/29", # Unilink AOVPN
    "83.98.63.176/29",   # Unilink AOVPN
    "78.33.10.50/31",    # Unilink AOVPN
    "78.33.10.52/30",    # Unilink AOVPN
    "78.33.10.56/30",    # Unilink AOVPN
    "78.33.10.60/32",    # Unilink AOVPN
    "78.33.32.99/32",    # Unilink AOVPN
    "78.33.32.100/30",   # Unilink AOVPN
    "78.33.32.104/30",   # Unilink AOVPN
    "78.33.32.108/32",   # Unilink AOVPN
    "217.138.45.109/32", # Unilink AOVPN
    "217.138.45.110/32", # Unilink AOVPN
  ]
  all_ingress_ips = concat(local.moj_ips, local.unilink_ips)

  legacy_test_natgw_ips = [
    "35.176.126.163/32",
    "35.178.162.73/32",
    "52.56.195.113/32"
  ]

  secret_prefix           = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}"
  application_secret_name = "${local.secret_prefix}-application-passwords"
  mis_account_id          = lookup(var.platform_vars.environment_management.account_ids, join("-", ["delius-mis", var.account_info.mp_environment]), null)

  oracle_db_server_names = {
    primarydb  = try(module.oracle_db_primary[0].oracle_db_server_name, "none"),
    standbydb1 = try(module.oracle_db_standby[0].oracle_db_server_name, "none"),
    standbydb2 = try(module.oracle_db_standby[1].oracle_db_server_name, "none")
  }

}
