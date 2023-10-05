locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    test = {
      apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    preproduction = {
      apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    production = {
      apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-production"]
    }
  }
}
