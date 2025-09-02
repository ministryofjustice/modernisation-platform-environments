module "ip_addresses" {
  source = "../../../../modules/ip_addresses"
}

locals {
  internal_security_group_cidrs = distinct(flatten([
    module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    module.ip_addresses.moj_cidrs.trusted_mojo_public,
    module.ip_addresses.moj_cidr.ark_dc_external_internet,
    module.ip_addresses.moj_cidr.vodafone_dia_networks,
    module.ip_addresses.moj_cidr.palo_alto_prisma_access_corporate,
    module.ip_addresses.moj_cidr.mojo_azure_landing_zone_egress,
  ]))
}
