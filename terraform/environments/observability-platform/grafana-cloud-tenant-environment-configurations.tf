# Grafana Cloud (GC) tenant configuration only.
# Amazon Managed Grafana tenant configuration lives in amg-tenant-environment-configurations.tf
#
# The schema, defaults and validation are in modules/grafana-cloud/tenant-configuration. A tenant
# has an optional `github_team`, which gives it a Grafana team and folder (grafana-cloud-sso.tf),
# and the AWS accounts it owns, keyed by account name. An account belongs to one tenant;
# `shared_with_tenants` lets other tenants' teams query it too. The defaults are:
#
#   "<account name>" = {
#     pdc_enabled         = false # opt in; must match the tenant module's grafana_cloud.pdc_agent.enabled
#     shared_with_tenants = []
#     cloudwatch          = { enabled = true, custom_namespaces = [] }
#     xray                = { enabled = false }
#     # Optional, with no default: adds an Amazon Managed Service for Prometheus data source
#     # amazon_prometheus = { workspace_id = "ws-...", region = "eu-west-2" }
#   }
#
# so `"<account name>" = {}` gives an account a CloudWatch data source (grafana-cloud-data-sources.tf).
# Set `pdc_enabled = true` only for accounts with private data sources to query, which gives them a
# PDC network (grafana-cloud-pdc-accounts.tf). AWS data sources use the account's `grafana-cloud`
# role, created by the tenant module.
locals {
  environment_configuration_gc = local.environment_configurations_gc[local.environment]
  environment_configurations_gc = {
    development = {
      pdc_token_rotator = {
        image_digest      = "sha256:e5f367b6af986020ff291b095f7ef0a44f56c7c7acd241fbaaae9484c81884c2" # v0.1.0-alpha.6
        bootstrap_enabled = true
      }
      pdc_failure_alerts = {
        slack_channel_id = "C06ALD6LX55"
      }
      tenant_configuration = {
        "observability-platform" = {
          github_team = "observability-platform"
          aws_accounts = {
            # No AWS data sources yet: observability-platform.tf still calls the tenant module at
            # 1.2.0, so this account has no grafana-cloud role.
            "observability-platform-development" = {
              cloudwatch = { enabled = false }
            }
            # Modernisation Platform sandbox accounts, used to test the tenant module and its PDC agent.
            "sprinkler-development" = {
              pdc_enabled = true
              xray        = { enabled = true }
            }
            "cooker-development" = {
              pdc_enabled = true
            }
            # Bootstrap centrally before deploying the Example agents.
            "example-development" = {
              pdc_enabled = true
            }
          }
        }
        # Other CP3 accounts belong in the future production stack, not this one.
        # The cloud-platform team already has query access via grafana-cloud-platform-access.tf.
        "cloud-platform" = {
          aws_accounts = {
            "cloud-platform-development" = { pdc_enabled = true }
          }
        }
      }
    }
    production = {
      pdc_token_rotator = {
        image_digest      = "sha256:e5f367b6af986020ff291b095f7ef0a44f56c7c7acd241fbaaae9484c81884c2" # v0.1.0-alpha.6
        bootstrap_enabled = true
      }
      pdc_failure_alerts = {
        slack_channel_id = "C06RA6C52TW"
      }
      tenant_configuration = {
        # The Cloud Platform and Container Platform accounts that use the production Grafana Cloud
        # stack. Each is bootstrapped centrally before its tenant module enables the PDC agent. The
        # cloud-platform team already has query access through grafana-cloud-platform-access.tf,
        # which maps container-platform-* accounts to it. Apply only after both rotator credentials
        # have been uploaded (docs/grafana-cloud/pdc-token-rotation.md).
        "cloud-platform" = {
          aws_accounts = {
            "cloud-platform-preproduction"     = { pdc_enabled = true }
            "cloud-platform-nonlive"           = { pdc_enabled = true }
            "cloud-platform-live"              = { pdc_enabled = true }
            "container-platform-octo-nonlive" = {
              pdc_enabled       = true
              amazon_prometheus = lookup(local.gc_cloud_platform_amp, "container-platform-octo-nonlive", null)
            }
            "container-platform-octo-live" = {
              pdc_enabled       = true
              amazon_prometheus = lookup(local.gc_cloud_platform_amp, "container-platform-octo-live", null)
            }
            "container-platform-laa-nonlive" = { pdc_enabled = true }
            "container-platform-laa-live"    = { pdc_enabled = true }
            "container-platform-hmpps-nonlive" = {
              pdc_enabled       = true
              amazon_prometheus = lookup(local.gc_cloud_platform_amp, "container-platform-hmpps-nonlive", null)
            }
            "container-platform-hmpps-live" = { pdc_enabled = true }
            "container-platform-cd-nonlive"    = { pdc_enabled = true }
            "container-platform-cd-live"       = { pdc_enabled = true }
          }
        }
      }
    }
  }
}

# Amazon Managed Service for Prometheus workspaces in the Cloud Platform (CP3) accounts.
#
# CP3's cluster-components creates the workspace in each business-unit account and publishes its ID
# to core-shared-services-production (cloud-platform/cluster-components/amp.tf), which is where the
# CP3 hub Grafana reads it too. Reading it here, rather than hard-coding it, keeps the data source
# right when a cluster and its workspace are rebuilt. Add an account here once its amp_enabled flag
# is true in cloud-platform/business-units.json, and its cluster-components has been applied; until
# then the parameter doesn't exist and the plan fails.
locals {
  gc_cloud_platform_amp_accounts = {
    development = []
    production = [
      "container-platform-octo-nonlive",
      "container-platform-octo-live",
      "container-platform-hmpps-nonlive",
    ]
  }
}

data "aws_ssm_parameter" "gc_cloud_platform_amp_workspace_id" {
  for_each = toset(local.gc_cloud_platform_amp_accounts[local.environment])
  provider = aws.shared-configuration-access

  # Both environments are in the platforms business unit, so this provider can read CP3's parameters.
  name = "/${lower(local.vpc_name)}/cloud-platform/amp/${each.key}/workspace-id"
}

locals {
  # Account name => amazon_prometheus settings, for the tenant configuration above. Workspace IDs
  # aren't secret, so insecure_value avoids marking the whole tenant configuration sensitive.
  gc_cloud_platform_amp = {
    for account, parameter in data.aws_ssm_parameter.gc_cloud_platform_amp_workspace_id :
    account => { workspace_id = parameter.insecure_value, region = "eu-west-2" }
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
