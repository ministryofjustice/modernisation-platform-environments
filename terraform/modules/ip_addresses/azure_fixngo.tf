locals {

  azure_fixngo_ip = {
    # Prod Domain Controllers
    PCMCW0011 = "10.40.128.196"
    PCMCW0012 = "10.40.0.133"
    pcmcw1011 = "10.40.144.196"
    pcmcw1012 = "10.40.64.133"

    # DevTest Domain Controllers
    MGMCW0002    = "10.102.0.196"
    tc_mgt_dc_01 = "10.102.0.199"
    tc_mgt_dc_02 = "10.102.0.200"
  }

  azure_fixngo_ips = {
    devtest = {
      domain_controllers = [
        local.azure_fixngo_ip.MGMCW0002,
        local.azure_fixngo_ip.tc_mgt_dc_01,
        local.azure_fixngo_ip.tc_mgt_dc_02,
      ]
    }
    prod = {
      domain_controllers = [
        local.azure_fixngo_ip.PCMCW0011,
        local.azure_fixngo_ip.PCMCW0012,
        local.azure_fixngo_ip.pcmcw1011,
        local.azure_fixngo_ip.pcmcw1012,
      ]
    }
  }

  azure_fixngo_cidr = {
    noms_live_vnet            = "10.40.0.0/18"
    noms_live_dr_vnet         = "10.40.64.0/18"
    noms_mgmt_live_vnet       = "10.40.128.0/20"
    noms_mgmt_live_dr_vnet    = "10.40.144.0/20"
    noms_transit_live_vnet    = "10.40.160.0/20"
    noms_transit_live_dr_vnet = "10.40.176.0/20"
    noms_test_vnet            = "10.101.0.0/16"
    noms_mgmt_vnet            = "10.102.0.0/16"
    noms_test_dr_vnet         = "10.111.0.0/16"
    noms_mgmt_dr_vnet         = "10.112.0.0/16"

    noms_transit_live_fw_devtest    = "52.142.189.87/32"
    noms_transit_live_fw_prod       = "52.142.189.118/32"
    noms_transit_live_dr_fw_devtest = "20.90.217.135/32"
    noms_transit_live_dr_fw_prod    = "20.90.217.127/32"
  }

  azure_fixngo_cidrs = {

    devtest = [
      local.azure_fixngo_cidr.noms_test_vnet,
      local.azure_fixngo_cidr.noms_mgmt_vnet,
      local.azure_fixngo_cidr.noms_test_dr_vnet,
      local.azure_fixngo_cidr.noms_mgmt_dr_vnet,
    ]

    prod = [
      local.azure_fixngo_cidr.noms_live_vnet,
      local.azure_fixngo_cidr.noms_mgmt_live_vnet,
      local.azure_fixngo_cidr.noms_live_dr_vnet,
      local.azure_fixngo_cidr.noms_mgmt_live_dr_vnet,
    ]

    internet_egress = [
      local.azure_fixngo_cidr.noms_transit_live_fw_devtest,
      local.azure_fixngo_cidr.noms_transit_live_fw_prod,
      local.azure_fixngo_cidr.noms_transit_live_dr_fw_devtest,
      local.azure_fixngo_cidr.noms_transit_live_dr_fw_prod,
    ]
  }

}
