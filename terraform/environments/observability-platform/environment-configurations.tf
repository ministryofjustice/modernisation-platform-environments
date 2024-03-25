locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      tenant_configuration = {
        "observability-platform" = {
          identity_centre_team = "observability-platform"
          alerting = {
            pagerduty = ["observability-platform"]
            slack     = ["observability-platform-alerts"]
          }
          aws_accounts = {
            "observability-platform-development" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = true
              xray_enabled            = true
            }
          }
        },
        "analytical-platform" = {
          identity_centre_team = "analytical-platform"
          aws_accounts = {
            "analytical-platform-ingestion-development" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
          }
        },
        "data-platform" = {
          "identity_centre_team" = "data-platform"
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
          "identity_centre_team" = "studio-webops"
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
          identity_centre_team = "observability-platform"
          aws_accounts = {
            "observability-platform-production" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = true
              xray_enabled            = true
            }
          }
        },
        "analytical-platform" = {
          identity_centre_team = "analytical-platform"
          aws_accounts = {
            "analytical-platform-ingestion-production" = {
              cloudwatch_enabled      = true
              prometheus_push_enabled = false
              xray_enabled            = true
            }
          }
        },
        "data-platform" = {
          "identity_centre_team" = "data-platform"
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
