locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      apps_tools_account_id                    = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
      apps_tools_eks_oidc_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/BEE86BED6494692D4ED31C2ED2319E13"
    }
    test = {
      // TODO: Replace with test values, keeping these as a placeholder
      apps_tools_account_id                    = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
      apps_tools_eks_oidc_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/BEE86BED6494692D4ED31C2ED2319E13"
    }
    preproduction = {
      // TODO: Replace with preproduction values, keeping these as a placeholder
      apps_tools_account_id                    = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
      apps_tools_eks_oidc_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/BEE86BED6494692D4ED31C2ED2319E13"
    }
    production = {
      // TODO: Replace with production values, keeping these as a placeholder
      apps_tools_account_id                    = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
      apps_tools_eks_oidc_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/BEE86BED6494692D4ED31C2ED2319E13"
    }
  }
}