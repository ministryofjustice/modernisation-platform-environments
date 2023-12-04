locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      observability_platform_configuration = {
        "data-platform" = {
          sso_uuid = "16a2d234-1031-70b5-2657-7f744c55e48f"
          cloudwatch_accounts = [
            "data-platform-development",
            "data-platform-test",
            "data-platform-staging",
            "data-platform-preproduction",
            "data-platform-apps-and-tools-development"
          ]
          prometheus_accounts = [
            "data-platform-apps-and-tools-development"
          ]
        }
      }
      source_accounts = [
        local.environment_management.account_ids["data-platform-apps-and-tools-development"],
        local.environment_management.account_ids["data-platform-development"],
        local.environment_management.account_ids["data-platform-test"],
        local.environment_management.account_ids["data-platform-preproduction"]
      ]
      data_platform_apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    test = {
      data_platform_apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    preproduction = {
      data_platform_apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-development"]
    }
    production = {
      source_accounts = [
        local.environment_management.account_ids["data-platform-production"],
        local.environment_management.account_ids["data-platform-apps-and-tools-production"]
      ]
      data_platform_apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-production"]
    }
  }
}

