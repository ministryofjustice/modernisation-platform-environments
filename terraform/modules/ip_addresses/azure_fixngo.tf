locals {

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
