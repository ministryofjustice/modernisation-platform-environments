locals {

  domain_types = { for dvo in aws_acm_certificate.nextcloud_external.domain_validation_options : dvo.domain_name => {
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

  globalprotect_ips = concat(
    module.ip_addresses.moj_cidr.moj_aws_digital_macos_globalprotect_alpha,
    module.ip_addresses.moj_cidr.moj_aws_digital_macos_globalprotect_prisma,
  )
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
  all_ingress_ips = concat(local.globalprotect_ips, local.unilink_ips)

}
