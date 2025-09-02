#### This file can be used to store locals specific to the member account ####

locals {
  delius_environments_per_account = {
    # account = [env1, env2]
    prod    = [] # prod
    preprod = ["stage", "preprod"]
    test    = []
    dev     = ["dev"]
  }

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]

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
