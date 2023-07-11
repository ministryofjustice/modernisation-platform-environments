locals {

  moj_cidr = {

    # for MoJ Digital Staff devices
    moj_digital_studio_office                 = "217.33.148.210/32"
    moj_digital_service_desk_vpn              = "81.134.202.29/32" # aka nurved, moj dsd
    moj_aws_digital_macos_globalprotect_alpha = "35.176.93.186/32"

    # for MOJ Official devices
    mojo_aws_globalprotect_vpc = "10.184.0.0/16"
    mojo_wifi                  = "10.154.0.0/15"

    # for MOJ Official devices internet access
    mojo_aws_preprod_byoip_cidr             = "51.149.251.0/24"
    mojo_aws_prod_byoip_cidr                = "51.149.250.0/24"
    mojo_arkc_internet_egress_exponential_e = "51.149.249.0/29"
    mojo_arkc_internet_egress_vodafone      = "194.33.249.0/29"
    mojo_arkf_internet_egress_exponential_e = "51.149.249.32/29"
    mojo_arkf_internet_egress_vodafone      = "194.33.248.0/29"

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
  }

  moj_cidrs = {

    trusted_moj_digital_staff_public = [
      local.moj_cidr.moj_digital_studio_office,
      local.moj_cidr.moj_digital_service_desk_vpn,
      local.moj_cidr.moj_aws_digital_macos_globalprotect_alpha,
    ]

    trusted_moj_enduser_internal = [
      local.moj_cidr.mojo_aws_globalprotect_vpc,
      local.moj_cidr.atos_arkc_ras,
      local.moj_cidr.atos_arkf_ras,
      local.moj_cidr.vodafone_wan_nicts_aggregate,
      local.moj_cidr.mojo_wifi,
      local.moj_cidr.mojo_azure_landing_zone,
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
