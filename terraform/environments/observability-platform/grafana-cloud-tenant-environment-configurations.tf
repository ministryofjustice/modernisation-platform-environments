# Grafana Cloud (GC) tenant configuration only.
# Amazon Managed Grafana tenant configuration lives in amg-tenant-environment-configurations.tf
#
# Features are selected per AWS account and must match the `features` the tenant
# module is deployed with in that account.
locals {
  environment_configuration_gc = local.environment_configurations_gc[local.environment]
  environment_configurations_gc = {
    development = {
      tenant_configuration = {
        "observability-platform" = {
          aws_accounts = {
            "observability-platform-development" = {
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
