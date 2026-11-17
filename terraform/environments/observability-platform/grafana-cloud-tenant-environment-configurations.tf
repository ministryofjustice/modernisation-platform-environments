# Grafana Cloud (GC) tenant configuration only.
# Amazon Managed Grafana tenant configuration lives in amg-tenant-environment-configurations.tf
#
# The schema, defaults and validation are in modules/grafana-cloud/tenant-configuration. A tenant
# has an optional `github_team`, which gives it a Grafana team and folder (grafana-cloud-sso.tf),
# and the AWS accounts it owns, keyed by account name. An account belongs to one tenant;
# `shared_with_tenants` lets other tenants' teams query it too. The defaults are:
#
#   "<account name>" = {
#     pdc_enabled         = true # must match the tenant module's grafana_cloud.pdc_agent.enabled
#     shared_with_tenants = []
#     cloudwatch          = { enabled = true, custom_namespaces = [] }
#     xray                = { enabled = false }
#     # Optional, with no default: adds an Amazon Managed Service for Prometheus data source
#     # amazon_prometheus = { workspace_id = "ws-...", region = "eu-west-2" }
#     push                = { metrics = false, logs = false, traces = false }
#   }
#
# so `"<account name>" = {}` gives an account a PDC network (grafana-cloud-pdc-accounts.tf) and a
# CloudWatch data source (grafana-cloud-data-sources.tf). AWS data sources use the account's
# `grafana-cloud` role, created by the tenant module. `push` gives the account a write token for the
# signals it sends to Grafana Cloud (grafana-cloud-push-accounts.tf), and lets the teams that can
# query the account see its data in the shared data sources (grafana-cloud-shared-data-sources.tf).
locals {
  environment_configuration_gc = local.environment_configurations_gc[local.environment]
  environment_configurations_gc = {
    development = {
      tenant_configuration = {
        "observability-platform" = {
          github_team = "observability-platform"
          aws_accounts = {
            # No AWS data sources yet: observability-platform.tf still calls the tenant module at
            # 1.2.0, so this account has no grafana-cloud role.
            "observability-platform-development" = {
              cloudwatch = { enabled = false }
            }
            # Modernisation Platform sandbox accounts, used to test the tenant module.
            "sprinkler-development" = {
              xray = { enabled = true }
              # Tests the Grafana Cloud path end to end: OTLP pushed with the account's write token
              # is visible to the team through the shared data sources.
              push = { metrics = true, logs = true, traces = true }
            }
            "cooker-development" = {}
          }
        }
      }
    }
    production = {
      tenant_configuration = {}
    }
  }
}

# Applies the defaults and validation
module "grafana_cloud_tenant_configuration" {
  source = "./modules/grafana-cloud/tenant-configuration"

  tenants = local.environment_configuration_gc.tenant_configuration
}

locals {
  gc_tenants  = module.grafana_cloud_tenant_configuration.tenants
  gc_accounts = module.grafana_cloud_tenant_configuration.accounts
}
