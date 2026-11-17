# Grafana Cloud (GC) tenant configuration only.
# Amazon Managed Grafana tenant configuration lives in amg-tenant-environment-configurations.tf
#
# Each AWS account gets its own PDC network and agent token (grafana-cloud-pdc-accounts.tf).
# `pdc_enabled` defaults to true and must match the tenant module's `grafana_cloud.pdc_agent.enabled`
# in that account, which also defaults to true.
locals {
  environment_configuration_gc = local.environment_configurations_gc[local.environment]
  environment_configurations_gc = {
    development = {
      tenant_configuration = {
        "observability-platform" = {
          github_team = "observability-platform"
          aws_accounts = {
            "observability-platform-development" = {
              pdc_enabled = true
            }
            # Modernisation Platform sandbox accounts, used to test the tenant module.
            "sprinkler-development" = {
              pdc_enabled = true
            }
            "cooker-development" = {
              pdc_enabled = true
            }
          }
        }
      }
    }
    production = {
      tenant_configuration = {}
    }
  }
}
