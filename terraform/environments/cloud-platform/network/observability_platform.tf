locals {
  # Gate the whole tenant module: inactive workspaces must not create IAM roles either.
  # Keep this list aligned with CP3 accounts with pdc_enabled in the development OP config.
  # Retain activated accounts and add later accounts one at a time (see ../README.md).
  pdc_tenant_workspaces = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
  ]
}

# Each activated account needs its central token secret bootstrapped before deployment.
module "observability_platform_tenant" {
  count = contains(local.pdc_tenant_workspaces, terraform.workspace) ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
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

# Preserve any existing active-workspace tenant resources when introducing the module gate.
moved {
  from = module.observability_platform_tenant
  to   = module.observability_platform_tenant[0]
}
