locals {
  ##
  # Variables used across multiple areas
  ##
  domain           = local.is-production ? "jitbit.cr.probation.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  non_prod_app_url = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.${local.domain}"
  prod_app_url     = "helpdesk.${local.domain}"
  app_url          = local.is-production ? local.prod_app_url : local.non_prod_app_url
  sandbox_app_url  = "${var.networking[0].application}-sandbox.${var.networking[0].business-unit}-${local.environment}.${local.domain}"

  acm_subject_alternative_names = local.is-development ? [local.app_url, local.sandbox_app_url, "blue-${local.sandbox_app_url}", "green-${local.sandbox_app_url}"] : [local.app_url]

  app_port = local.application_data.accounts[local.environment].server_port

  ##
  # Variables used by certificate validation, as part of the load balancer listener, cert and route 53 record configuration
  ##
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main                = [for k, v in local.domain_types : v.name if k == local.domain]
  domain_name_sub                 = [for k, v in local.domain_types : v.name if k == local.app_url]
  domain_name_sub_sandbox         = [for k, v in local.domain_types : v.name if k == local.sandbox_app_url]
  domain_name_sub_sandbox_blue    = [for k, v in local.domain_types : v.name if k == "blue-${local.sandbox_app_url}"]
  domain_name_sub_sandbox_green   = [for k, v in local.domain_types : v.name if k == "green-${local.sandbox_app_url}"]
  domain_record_main              = [for k, v in local.domain_types : v.record if k == local.domain]
  domain_record_sub               = [for k, v in local.domain_types : v.record if k == local.app_url]
  domain_record_sub_sandbox       = [for k, v in local.domain_types : v.record if k == local.sandbox_app_url]
  domain_record_sub_sandbox_blue  = [for k, v in local.domain_types : v.record if k == "blue-${local.sandbox_app_url}"]
  domain_record_sub_sandbox_green = [for k, v in local.domain_types : v.record if k == "green-${local.sandbox_app_url}"]
  domain_type_main                = [for k, v in local.domain_types : v.type if k == local.domain]
  domain_type_sub                 = [for k, v in local.domain_types : v.type if k == local.app_url]
  domain_type_sub_sandbox         = [for k, v in local.domain_types : v.type if k == local.sandbox_app_url]
  domain_type_sub_sandbox_blue    = [for k, v in local.domain_types : v.type if k == "blue-${local.sandbox_app_url}"]
  domain_type_sub_sandbox_green   = [for k, v in local.domain_types : v.type if k == "green-${local.sandbox_app_url}"]

  validation_record_fqdns = local.is-development ? [local.domain_name_main[0], local.domain_name_sub[0], local.domain_name_sub_sandbox[0], local.domain_name_sub_sandbox_blue[0], local.domain_name_sub_sandbox_green[0]] : [local.domain_name_main[0], local.domain_name_sub[0]]

  internal_security_group_cidrs = distinct(flatten([
    module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    module.ip_addresses.moj_cidrs.trusted_mojo_public,
    module.ip_addresses.moj_cidr.ark_dc_external_internet,
    module.ip_addresses.moj_cidr.vodafone_dia_networks,
    module.ip_addresses.moj_cidr.palo_alto_prisma_access_corporate,
    module.ip_addresses.moj_cidr.mojo_azure_landing_zone_egress,
    [
      # Route53 Healthcheck Access Cidrs
      # London Region not support yet, so metrics are not yet publised, can be enabled at later stage for Route53 endpoint monitor
      "15.177.0.0/18",     # GLOBAL Region
      "54.251.31.128/26",  # ap-southeast-1 Region
      "54.255.254.192/26", # ap-southeast-1 Region
      "176.34.159.192/26", # eu-west-1 Region
      "54.228.16.0/26",    # eu-west-1 Region
      "107.23.255.0/26",   # us-east-1 Region
      "54.243.31.192/26"   # us-east-1 Region
    ]
  ]))

  ipv6_cidr_blocks = [
    # Route53 Healthcheck Access Cidrs IPv6
    "2406:da18:7ff:f800::/53",  # ap-southeast-1 Region
    "2406:da18:fff:f800::/53",  # ap-southeast-1 Region
    "2a05:d018:fff:f800::/53",  # eu-west-1 Region
    "2a05:d018:7ff:f800::/53",  # eu-west-1 Region
    "2600:1f18:7fff:f800::/53", # us-east-1 Region
    "2600:1f18:3fff:f800::/53", # us-east-1 Region
  ]
}