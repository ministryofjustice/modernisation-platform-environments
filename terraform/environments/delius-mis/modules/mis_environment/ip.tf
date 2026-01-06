module "ip_addresses" {
  source = "../../../../modules/ip_addresses"
}

locals {
  # Split the CIDRs into smaller groups to avoid hitting the 60-rule limit per security group
  internal_security_group_cidrs_staff = module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public
  internal_security_group_cidrs_mojo  = module.ip_addresses.moj_cidrs.trusted_mojo_public
  internal_security_group_cidrs_infrastructure = distinct(flatten([
    module.ip_addresses.moj_cidr.ark_dc_external_internet,
    module.ip_addresses.moj_cidr.vodafone_dia_networks,
    module.ip_addresses.moj_cidr.palo_alto_prisma_access_corporate,
    module.ip_addresses.moj_cidr.mojo_azure_landing_zone_egress,
  ]))
}
