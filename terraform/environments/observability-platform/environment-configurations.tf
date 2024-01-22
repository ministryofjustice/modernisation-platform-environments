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
        },
        "digital-studio-operations" = {
          sso_uuid = "9c6710dd7f-120a1f73-34c1-447a-b34c-6cdc2cd64b5e"
          cloudwatch_accounts = [
            "nomis-test",
            "oasys-test"
          ]
        }
      }
      tenant_configuration = {
        "observability-platform" = {
          identity_centre_team = "16a2d234-1031-70b5-2657-7f744c55e48f" # This is current hard coded to their UUID as we can't lookup by name from our account
          aws_accounts = {
            "observability-platform-development" = {
              cloudwatch_enabled = true
              prometheus_enabled = true
              xray_enabled       = true
            }
          }
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
      tenant_configuration = {}
    }
  }
}
