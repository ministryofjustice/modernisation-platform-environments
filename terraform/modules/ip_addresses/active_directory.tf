locals {

  # active directory
  active_directory_cidrs = {
    # azure.noms.root
    azure = {
      domain_controllers = concat(
        local.mp_cidrs.ad_fixngo_azure_domain_controllers,
        local.azure_fixngo_cidrs.devtest_domain_controllers
      )

      jumpservers = concat(
        local.azure_fixngo_cidrs.devtest_jumpservers,
        # MP jumpservers are in ASGs so could be any IP in hmpps VPC
      )

      rdgateways = concat(
        local.azure_fixngo_cidrs.devtest_rdgateways,
        # MP gateways are in ASGs so could be any IP in hmpps VPC
      )
    }

    # azure.hmpp.root
    hmpp = {
      domain_controllers = concat(
        local.mp_cidrs.ad_fixngo_hmpp_domain_controllers,
        local.azure_fixngo_cidrs.prod_domain_controllers
      )

      jumpservers = concat(
        local.azure_fixngo_cidrs.prod_jumpservers,
        # MP jumpservers are in ASGs so could be any IP in hmpps VPC
      )

      rdgateways = concat(
        local.azure_fixngo_cidrs.prod_rdgateways,
        # MP gateways are in ASGs so could be any IP in hmpps VPC
      )
    }
  }
}
