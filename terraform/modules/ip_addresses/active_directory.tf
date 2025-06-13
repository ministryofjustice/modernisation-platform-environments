locals {

  # active directory
  active_directory_cidrs = {
    # azure.noms.root
    azure = {
      domain_controllers = concat(
        local.azure_fixngo_cidrs.devtest_domain_controllers,
        local.mp_cidrs.ad_fixngo_azure_domain_controllers
      )
    }

    # azure.hmpp.root
    hmpp = {
      domain_controllers = concat(
        local.azure_fixngo_cidrs.prod_domain_controllers,
        local.mp_cidrs.ad_fixngo_hmpp_domain_controllers
      )
    }
  }
}
