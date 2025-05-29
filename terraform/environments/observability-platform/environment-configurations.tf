locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      tenant_configuration = {
        "modernisation-platform" = {
          identity_centre_team = "modernisation-platform"
          slack_channels       = ["mod-plat-observ-test"]
          aws_accounts = {
            "cooker-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = true
              athena_config = {
                primary = {
                  database  = "grafana_db"
                  workgroup = "grafana-dashboard"
                }
              }
            }
          }
        },
        "observability-platform" = {
          identity_centre_team = "observability-platform"
          slack_channels       = ["observability-platform-development-alerts"]
          pagerduty_services   = ["observability-platform"]
          aws_accounts = {
            "observability-platform-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = true
              athena_enabled                  = false
            }
          }
        }
      }
      grafana_version                 = "10.4"
      grafana_api_key_rotator_version = "1.0.10"
    }
    production = {
      tenant_configuration = {
        "observability-platform" = {
          identity_centre_team = "observability-platform"
          slack_channels       = ["observability-platform-production-alerts"]
          aws_accounts = {
            "observability-platform-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = true
              athena_enabled                  = false
            }
          }
        },
        "analytical-platform" = {
          identity_centre_team = "analytical-platform"
          aws_accounts = {
            "analytical-platform-common-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "analytical-platform-compute-development" = {
              cloudwatch_enabled                 = true
              prometheus_push_enabled            = false
              amazon_prometheus_query_enabled    = true
              amazon_prometheus_workspace_region = "eu-west-2"
              amazon_prometheus_workspace_id     = "ws-bfdd5d7a-5571-4686-bfd4-43ab07cf8d54ba"
              xray_enabled                       = true
              athena_enabled                     = false
            },
            "analytical-platform-compute-production" = {
              cloudwatch_enabled                 = true
              prometheus_push_enabled            = false
              amazon_prometheus_query_enabled    = true
              amazon_prometheus_workspace_region = "eu-west-2"
              amazon_prometheus_workspace_id     = "ws-257796b7-4aa4-4c18-b906-6dd21e95d7b73e"
              xray_enabled                       = true
              athena_enabled                     = false
            },
            "analytical-platform-compute-test" = {
              cloudwatch_enabled                 = true
              prometheus_push_enabled            = false
              amazon_prometheus_query_enabled    = true
              amazon_prometheus_workspace_region = "eu-west-2"
              amazon_prometheus_workspace_id     = "ws-a9d7f576-58b7-4748-b4c1-b02bbdc54a2922"
              xray_enabled                       = true
              athena_enabled                     = false
            },
            "analytical-platform-ingestion-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = true
              athena_enabled                  = false
            },
            "analytical-platform-ingestion-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = true
              athena_enabled                  = false
            },
            "analytical-platform-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
            "analytical-platform-production" = {
              cloudwatch_enabled                 = true
              prometheus_push_enabled            = false
              amazon_prometheus_query_enabled    = true
              amazon_prometheus_workspace_region = "eu-west-1"
              amazon_prometheus_workspace_id     = "ws-a7b353be-244a-47e7-8054-436b41c050d932"
              xray_enabled                       = false
              athena_enabled                     = false
            },
            "analytical-platform-data-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "analytical-platform-data-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "analytical-platform-landing-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "analytical-platform-management-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
          }
        },
        "ccms-ebs" = {
          "identity_centre_team" = "laa-ccms-migration-team",
          "aws_accounts" = {
            "ccms-ebs-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "ccms-ebs-preproduction" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "ccms-ebs-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "ccms-ebs-test" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "ccms-ebs-upgrade-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "ccms-ebs-upgrade-test" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
          }
        },
        "data-engineering" = {
          "identity_centre_team" = "data-engineering",
          "aws_accounts" = {
            "analytical-platform-data-engineering-sandboxa" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "analytical-platform-data-engineering-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
          }
        },
        "digital-prison-reporting" = {
          "identity_centre_team" = "hmpps-digital-prison-reporting",
          "aws_accounts" = {
            "digital-prison-reporting-development" = {
              cloudwatch_enabled              = true
              cloudwatch_custom_namespaces    = "DPRAgentCustomMetrics,DPRDataReconciliationCustom"
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "digital-prison-reporting-preproduction" = {
              cloudwatch_enabled              = true
              cloudwatch_custom_namespaces    = "DPRAgentCustomMetrics,DPRDataReconciliationCustom"
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "digital-prison-reporting-production" = {
              cloudwatch_enabled              = true
              cloudwatch_custom_namespaces    = "DPRAgentCustomMetrics,DPRDataReconciliationCustom"
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "digital-prison-reporting-test" = {
              cloudwatch_enabled              = true
              cloudwatch_custom_namespaces    = "DPRAgentCustomMetrics,DPRDataReconciliationCustom"
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
          }
        },
        "modernisation-platform" = {
          identity_centre_team = "modernisation-platform"
          slack_channels       = ["mod-plat-observ-test"]
          aws_accounts = {
            "core-network-services-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "core-logging-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = true
              athena_config = {
                mod-platform-cur-reports = {
                  database  = "moj-cur-athena-db"
                  workgroup = "mod-platform-cur-reports"
                }
              }
            },
            "core-security-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "core-shared-services-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "core-vpc-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            },
            "modernisation-platform" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = false
            }
          }
        },
        "green-ops" = {
          "identity_centre_team" = "green-ops",
          "aws_accounts" = {
            "example-development" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = true
              athena_config = {
                primary = {
                  database  = "greenops_cur_poc"
                  workgroup = "primary"
                }
              }
            }
          }
        },
        "coat" = {
          "identity_centre_team" = "cloud-optimisation-and-accountability",
          "aws_accounts" = {
            "coat-production" = {
              cloudwatch_enabled              = true
              prometheus_push_enabled         = false
              amazon_prometheus_query_enabled = false
              xray_enabled                    = false
              athena_enabled                  = true
              athena_config = {
                primary = {
                  database  = "cur_v2_database"
                  workgroup = "coat_cur_report"
                }
              }
            }
          }
        }
      }
      grafana_version                 = "10.4"
      grafana_api_key_rotator_version = "1.0.10"
    }
  }
}
