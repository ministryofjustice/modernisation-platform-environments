locals {

  moj_cidr = {

    # for MoJ Digital Staff devices
    moj_digital_studio_office = "217.33.148.210/32"
    # moj_digital_service_desk_vpn            = "81.134.202.29/32" # aka nurved, moj dsd - decommissioned
    moj_aws_digital_macos_globalprotect_alpha = [
      "18.169.147.172/32",
      "35.176.93.186/32",
      "18.130.148.126/32",
      "35.176.148.126/32"
    ]

    # for MOJ Official devices
    mojo_aws_globalprotect_vpc = "10.184.0.0/14"
    mojo_wifi                  = "10.154.0.0/15"

    # for MOJ Official devices internet access
    mojo_aws_preprod_byoip_cidr             = "51.149.251.0/24"
    mojo_aws_prod_byoip_cidr                = "51.149.250.0/24"
    mojo_arkc_internet_egress_exponential_e = "51.149.249.0/29"
    mojo_arkc_internet_egress_vodafone      = "194.33.249.0/29"
    mojo_arkf_internet_egress_exponential_e = "51.149.249.32/29"
    mojo_arkf_internet_egress_vodafone      = "194.33.248.0/29"

    ark_dc_external_internet = [
      "195.59.75.0/24",
      "194.33.192.0/25",
      "194.33.193.0/25",
      "194.33.196.0/25",
      "194.33.197.0/25"
    ]

    # Ian Norris: for sites that don't go through prisma
    vodafone_dia_networks = [
      "194.33.200.0/21",
      "194.33.216.0/23",
      "194.33.218.0/24"
    ]

    # Ian Norris: For moj_wifi sites without prisma, in case we break out locally for prisma sites
    # Aggregating 213.107.164.0/24 213.107.165.0/24 213.107.166.0/24 213.107.167.0/24 to save on SG rules
    VM02_dia_networks = "213.107.164.0/22"

    mojo_azure_landing_zone_egress = [
      "20.49.214.199/32",
      "20.49.214.228/32",
      "20.26.11.71/32",
      "20.26.11.108/32"
    ]

    palo_alto_prisma_access_corporate   = "128.77.75.64/26" # MacOS Global Protect
    palo_alto_prisma_access_third_party = "128.77.75.0/26"
    palo_alto_prisma_access_residents   = "128.77.75.128/26"

    # for devices connected to Prison Networks
    vodafone_wan_nicts_aggregate = "10.80.0.0/12"
    # For users without an MOJ Official device, e.g. private prisons
    mojo_azure_landing_zone = "10.192.0.0/16"

    # for DOM1 devices connected to Cisco RAS VPN
    atos_arkc_ras = "10.175.0.0/16"
    atos_arkf_ras = "10.176.0.0/16"

    # for connectivity from other platforms
    aws_cloud_platform_vpc            = "172.20.0.0/16"
    aws_analytical_platform_aggregate = "10.200.0.0/15"
    aws_data_engineering_dev          = "172.24.0.0/16"
    aws_data_engineering_prod         = "172.25.0.0/16"
    aws_data_engineering_stage        = "172.26.0.0/16"
    aws_xsiam_prod_vpc                = "10.180.96.0/22"
  }

  moj_cidrs = {

    trusted_moj_digital_staff_public = flatten([
      local.moj_cidr.moj_digital_studio_office,
      local.moj_cidr.moj_aws_digital_macos_globalprotect_alpha,
      local.moj_cidr.palo_alto_prisma_access_corporate,
      local.moj_cidr.mojo_aws_preprod_byoip_cidr,
      local.moj_cidr.mojo_aws_prod_byoip_cidr,
      local.moj_cidr.mojo_arkc_internet_egress_exponential_e,
      local.moj_cidr.mojo_arkc_internet_egress_vodafone,
      local.moj_cidr.mojo_arkf_internet_egress_exponential_e,
      local.moj_cidr.mojo_arkf_internet_egress_vodafone,
      local.moj_cidr.ark_dc_external_internet,
      local.moj_cidr.mojo_azure_landing_zone_egress,
      local.moj_cidr.vodafone_dia_networks,
      local.moj_cidr.VM02_dia_networks,
    ])

    trusted_moj_enduser_internal = [
      local.moj_cidr.mojo_aws_globalprotect_vpc,
      local.moj_cidr.atos_arkc_ras,
      local.moj_cidr.atos_arkf_ras,
      local.moj_cidr.vodafone_wan_nicts_aggregate,
      local.moj_cidr.mojo_wifi,
      local.moj_cidr.mojo_azure_landing_zone
    ]

    trusted_mojo_public = [
      local.moj_cidr.mojo_aws_preprod_byoip_cidr,
      local.moj_cidr.mojo_aws_prod_byoip_cidr,
      local.moj_cidr.mojo_arkc_internet_egress_exponential_e,
      local.moj_cidr.mojo_arkc_internet_egress_vodafone,
      local.moj_cidr.mojo_arkf_internet_egress_exponential_e,
      local.moj_cidr.mojo_arkf_internet_egress_vodafone,
    ]
  }
}
