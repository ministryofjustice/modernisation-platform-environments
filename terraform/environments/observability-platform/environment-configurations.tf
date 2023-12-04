locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      observability_platform_configuration = {
        "data-platform" = {
          sso_uuid = "a68242b4-b0a1-7085-25f4-dc60e4c122c0"
          cloudwatch_accounts = [
            "data-platform-development",
            "data-platform-test",
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
    production = {
      observability_platform_configuration = {
        "data-platform" = {
          sso_uuid = "a68242b4-b0a1-7085-25f4-dc60e4c122c0"
          cloudwatch_accounts = [
            "data-platform-production",
            "data-platform-apps-and-tools-production"
          ]
          prometheus_accounts = [
            "data-platform-apps-and-tools-production"
          ]
        }
      }
      source_accounts = [
        local.environment_management.account_ids["data-platform-production"],
        local.environment_management.account_ids["data-platform-apps-and-tools-production"]
      ]
      data_platform_apps_tools_account_id = local.environment_management.account_ids["data-platform-apps-and-tools-production"]
    }
  }
}

