locals {

  azure_fixngo_ip = {
    # Prod Domain Controllers
    PCMCW0011 = "10.40.128.196"
    PCMCW0012 = "10.40.0.133"

    # DevTest Domain Controllers
    MGMCW0002 = "10.102.0.196"
  }

  azure_fixngo_ips = {
    devtest = {
      domain_controllers = [
        local.azure_fixngo_ip.MGMCW0002,
      ]
    }
    prod = {
      domain_controllers = [
        local.azure_fixngo_ip.PCMCW0011,
        local.azure_fixngo_ip.PCMCW0012,
      ]
    }
  }

  azure_fixngo_cidr = {
    noms_live_vnet         = "10.40.0.0/18"
    noms_mgmt_live_vnet    = "10.40.128.0/20"
    noms_transit_live_vnet = "10.40.160.0/20"
    noms_test_vnet         = "10.101.0.0/16"
    noms_mgmt_vnet         = "10.102.0.0/16"

    noms_transit_live_fw_devtest = "52.142.189.87/32"
    noms_transit_live_fw_prod    = "52.142.189.118/32"

    noms_prod_domain_controller_PCMCW0011 = "10.40.128.196/32"
    noms_prod_domain_controller_PCMCW0012 = "10.40.0.133/32"
    noms_prod_rdgateway_PDMRW0001         = "10.40.128.133/32"

    noms_devtest_domain_controller_MGMCW0002 = "10.102.0.196/32"
    noms_devtest_rdgateway_MGMRW0001         = "10.102.0.132/32"
  }

  noms_live_subnet = {
    noms_live_core                                = "10.40.0.128/26"
    hmpps_prod_ukwest_clientaccess_appgateway1    = "10.40.2.0/27"
    hmpps_prod_ukwest_clientaccess_appgateway2    = "10.40.2.32/27"
    hmpps_preprod_ukwest_clientaccess_appgateway1 = "10.40.2.64/27"
    hmpps_prod_ukwest_clientaccess_appgateway3    = "10.40.2.160/27"
    pd_prisonnomis_clientaccess                   = "10.40.3.0/26"
    pd_prisonnomis_app                            = "10.40.3.64/26"
    pd_prisonnomis_db                             = "10.40.3.128/26"
    pd_prisonnomis_ndh                            = "10.40.3.192/26"
    pd_prisonnomis_clientaccess_gateway           = "10.40.4.0/26"
    pd_oasys_clientaccess                         = "10.40.6.0/26"
    pd_oasys_app                                  = "10.40.6.64/26"
    pd_oasys_db                                   = "10.40.6.128/26"
    pd_oasys_clientaccess_gateway                 = "10.40.6.192/26"
    pd_csr_clientaccess                           = "10.40.8.0/26"
    pd_csr_app                                    = "10.40.8.64/26"
    pd_csr_db                                     = "10.40.8.128/26"
    pd_csr_clientaccess_gateway                   = "10.40.8.192/26"
    pd_noncore_db                                 = "10.40.10.128/26"
    pp_noncore_db                                 = "10.40.11.128/26"
    pd_cafm_clientaccess                          = "10.40.15.0/26"
    pd_cafm_app                                   = "10.40.15.64/26"
    pd_cafm_db                                    = "10.40.15.128/26"
    pd_cafm_clientaccess_gateway                  = "10.40.15.192/26"
    pp_prisonnomis_clientaccess                   = "10.40.37.0/26"
    pp_prisonnomis_app                            = "10.40.37.64/26"
    pp_prisonnomis_db                             = "10.40.37.128/26"
    pp_prisonnomis_ndh                            = "10.40.37.192/26"
    pp_prisonnomis_clientaccess_gateway           = "10.40.38.0/26"
    pp_oasys_clientaccess                         = "10.40.40.0/26"
    pp_oasys_app                                  = "10.40.40.64/26"
    pp_oasys_db                                   = "10.40.40.128/26"
    pp_oasys_clientaccess_gateway                 = "10.40.40.192/26"
    pp_csr_clientaccess                           = "10.40.42.0/26"
    pp_csr_app                                    = "10.40.42.64/26"
    pp_csr_db                                     = "10.40.42.128/26"
    pp_csr_clientaccess_gateway                   = "10.40.42.192/26"
    ls_prisonnomis_clientaccess                   = "10.40.44.0/27"
    ls_prisonnomis_app                            = "10.40.44.32/27"
    ls_prisonnomis_db                             = "10.40.44.64/27"
    ls_prisonnomis_ndh                            = "10.40.44.96/27"
    pp_cafm_clientaccess                          = "10.40.50.0/26"
    pp_cafm_app                                   = "10.40.50.64/26"
    pp_cafm_db                                    = "10.40.50.128/26"
    pp_cafm_clientaccess_gateway                  = "10.40.50.192/26"
    pp_mercury                                    = "10.40.54.0/24"
    pd_mercury                                    = "10.40.55.0/24"
    pd_lss                                        = "10.40.56.0/28"
  }

  noms_mgmt_live_subnet = {
    noms_mgmt_live_remoteaccess = "10.40.128.128/26"
    noms_mgmt_live_core         = "10.40.128.192/26"
    noms_mgmt_live_tools        = "10.40.129.0/26"
    noms_mgmt_live_jumpservers  = "10.40.129.64/26"
    noms_mgmt_live_tvm          = "10.40.130.16/28"
  }
  noms_test_subnet = {
    noms_test_core                                = "10.101.0.128/26"
    hmpps_devtest_ukwest_clientaccess_appgateway1 = "10.101.2.0/27"
    hmpps_devtest_ukwest_clientaccess_appgateway2 = "10.101.2.32/27"
    hmpps_devtest_ukwest_clientaccess_appgateway3 = "10.101.2.64/27"
    t1_prisonnomis_clientaccess                   = "10.101.3.0/26"
    t1_prisonnomis_app                            = "10.101.3.64/26"
    t1_prisonnomis_db                             = "10.101.3.128/26"
    t1_prisonnomis_ndh                            = "10.101.3.192/26"
    t1_oasys_clientaccess                         = "10.101.6.0/26"
    t1_oasys_app                                  = "10.101.6.64/26"
    t1_oasys_db                                   = "10.101.6.128/26"
    t1_noncore_app                                = "10.101.11.64/26"
    t2_prisonnomis_clientaccess                   = "10.101.33.0/26"
    t2_prisonnomis_db                             = "10.101.33.128/26"
    t2_prisonnomis_ndh                            = "10.101.33.192/26"
    t2_oasys_clientaccess                         = "10.101.36.0/26"
    t2_oasys_app                                  = "10.101.36.64/26"
    t2_oasys_db                                   = "10.101.36.128/26"
    t3_prisonnomis_clientaccess                   = "10.101.63.0/26"
    t3_prisonnomis_db                             = "10.101.63.128/26"
    t3_csr_clientaccess                           = "10.101.69.0/26"
    t3_csr_app                                    = "10.101.69.64/26"
    t3_csr_db                                     = "10.101.69.128/26"
    sd_prisonnomis                                = "10.101.93.0/24"
  }
  noms_mgmt_subnet = {
    nomsmgmt_remoteaccess         = "10.102.0.128/26"
    nomsmgmt_core                 = "10.102.0.192/26"
    nomsmgmt_tools                = "10.102.1.0/26"
    nomsmgmt_jumpservers_test     = "10.102.1.64/26"
    nomsmgmt_patchacquisition     = "10.102.1.128/26"
    nomsmgmtjumpservers_test_temp = "10.102.1.192/26"
    nomsmgmt_proxy_inner          = "10.102.3.0/26"
    nomsmgmt_proxy_outer          = "10.102.3.64/26"
    noms_mgmt_tvm                 = "10.102.5.0/28"
  }

  azure_fixngo_cidrs = {

    devtest_core = [
      local.noms_test_subnet.noms_test_core,
    ]

    devtest = [
      local.azure_fixngo_cidr.noms_test_vnet,
      local.azure_fixngo_cidr.noms_mgmt_vnet,
    ]

    devtest_domain_controllers = [
      local.azure_fixngo_cidr.noms_devtest_domain_controller_MGMCW0002,
    ]

    devtest_jumpservers = [
      local.noms_mgmt_subnet.nomsmgmt_jumpservers_test,
      local.noms_mgmt_subnet.nomsmgmtjumpservers_test_temp,
      local.noms_mgmt_subnet.nomsmgmt_remoteaccess,
    ]

    devtest_rdgateways = [
      local.azure_fixngo_cidr.noms_devtest_rdgateway_MGMRW0001,
    ]

    devtest_tools = [
      local.noms_mgmt_subnet.nomsmgmt_tools,
    ]

    prod_core = [
      local.noms_live_subnet.noms_live_core,
    ]

    prod = [
      local.azure_fixngo_cidr.noms_live_vnet,
      local.azure_fixngo_cidr.noms_mgmt_live_vnet,
    ]

    prod_domain_controllers = [
      local.azure_fixngo_cidr.noms_prod_domain_controller_PCMCW0011,
      local.azure_fixngo_cidr.noms_prod_domain_controller_PCMCW0012,
    ]

    prod_jumpservers = [
      local.noms_mgmt_live_subnet.noms_mgmt_live_jumpservers,
      local.noms_mgmt_live_subnet.noms_mgmt_live_remoteaccess,
    ]

    prod_rdgateways = [
      local.azure_fixngo_cidr.noms_prod_rdgateway_PDMRW0001,
    ]

    prod_tools = [
      local.noms_mgmt_live_subnet.noms_mgmt_live_tools,
    ]

    internet_egress = [
      local.azure_fixngo_cidr.noms_transit_live_fw_devtest,
      local.azure_fixngo_cidr.noms_transit_live_fw_prod,
    ]
  }

}
