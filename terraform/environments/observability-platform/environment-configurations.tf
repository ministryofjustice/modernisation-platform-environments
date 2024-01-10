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
        "digital-studio-operations" = {
          sso_uuid = "9c6710dd7f-120a1f73-34c1-447a-b34c-6cdc2cd64b5e"
          cloudwatch_accounts = [
            "nomis-test",
            "oasys-test"
          ]
        }
      }
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
    }
  }
}
