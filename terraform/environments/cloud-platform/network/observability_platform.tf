locals {
  # Grafana Cloud stack for every CP3 network workspace. The Observability Platform account is derived from the stack,
  # so an account's token secret, restarter trust and stack always come from the same environment.
  # Production-stack accounts stay disabled until Observability Platform production supports PDC; then enable one
  # account per pull request, and never disable an enabled account (see ../README.md).
  pdc_tenant_workspaces = {
    cloud-platform-development       = { stack = "development", enabled = true }
    cloud-platform-preproduction     = { stack = "production", enabled = false }
    cloud-platform-nonlive           = { stack = "production", enabled = false }
    cloud-platform-live              = { stack = "production", enabled = false }
    container-platform-octo-nonlive  = { stack = "production", enabled = false }
    container-platform-octo-live     = { stack = "production", enabled = false }
    container-platform-laa-nonlive   = { stack = "production", enabled = false }
    container-platform-laa-live      = { stack = "production", enabled = false }
    container-platform-hmpps-nonlive = { stack = "production", enabled = false }
    container-platform-hmpps-live    = { stack = "production", enabled = false }
    container-platform-cd-nonlive    = { stack = "production", enabled = false }
    container-platform-cd-live       = { stack = "production", enabled = false }
  }

  pdc_tenant = local.pdc_tenant_workspaces[terraform.workspace]
}

# Gate the whole tenant module: disabled workspaces must not create IAM roles either.
# Each enabled account needs its central token secret bootstrapped before deployment.
module "observability_platform_tenant" {
  count = local.pdc_tenant.enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=019e7a949d889bd1e132bc508c2c6f59224a052e" # v3.2.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-${local.pdc_tenant.stack}"]

  # CP3 uses Grafana Cloud only. Its grafana-cloud role still gets CloudWatch, Amazon Managed Prometheus and X-Ray access.
  enable_amazon_managed_grafana = false

  grafana_cloud = {
    stack = local.pdc_tenant.stack
    pdc_agent = {
      enabled = true
      # CP3 owns its subnets; the module's default *-general-private-* lookup does not apply.
      subnet_ids = module.cluster_vpc.private_subnets
      allowed_targets = [
        { cidr_block = local.vpc_cidr[local.cp_vpc_name].primary, port = 443 },
      ]
    }
  }

  tags = local.tags
}

# Preserve any existing enabled-workspace tenant resources when introducing the module gate.
moved {
  from = module.observability_platform_tenant
  to   = module.observability_platform_tenant[0]
}
