locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      tenant_configuration = {
        "observability-platform" = {
          identity_centre_team = "16a2d234-1031-70b5-2657-7f744c55e48f"
          aws_accounts = {
            "observability-platform-development" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = true
              xray_enabled            = true
            }
          }
        }
        "data-platform" = {
          "identity_centre_team" = "a68242b4-b0a1-7085-25f4-dc60e4c122c0"
          "aws_accounts" = {
            "data-platform-development" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
            "data-platform-test" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
            "data-platform-preproduction" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
            "data-platform-apps-and-tools-development" = {
              cloudwatch_enabled        = true
              "prometheus_push_enabled" = true
              xray_enabled              = true
            }
          }
        }
        "digital-studio-operations" = {
          "identity_centre_team" = "9c6710dd7f-120a1f73-34c1-447a-b34c-6cdc2cd64b5e"
          "aws_accounts" = {
            "nomis-test" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = false
            }
            "oasys-test" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = false
            }
          }
        }
      }
    }
    production = {
      tenant_configuration = {
        "observability-platform" = {
          identity_centre_team = "16a2d234-1031-70b5-2657-7f744c55e48f"
          aws_accounts = {
            "observability-platform-production" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = true
              xray_enabled            = true
            }
          }
        }
        "data-platform" = {
          "identity_centre_team" = "a68242b4-b0a1-7085-25f4-dc60e4c122c0"
          "aws_accounts" = {
            "data-platform-production" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
            "data-platform-apps-and-tools-production" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = true
              xray_enabled            = true
            }
          }
        }
      }
    }
  }
}
