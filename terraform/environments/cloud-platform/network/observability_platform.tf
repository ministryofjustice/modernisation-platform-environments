locals {
  # PDC agents are enabled in batches because the central token rotator bootstraps and enrols
  # one account at a time. Keep this list identical to the accounts with `pdc_enabled = true` in
  # the development Observability Platform tenant configuration. Add the next batch only after
  # every account here has completed enrolment (see ../README.md).
  pdc_agent_workspaces = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
  ]
}

# Every CP3 account gets the tenant roles for its CloudWatch data source. PDC agents need the
# account's central token secret to be bootstrapped first.
module "observability_platform_tenant" {
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      enabled = contains(local.pdc_agent_workspaces, terraform.workspace)
      # CP3 owns its subnets; the module's default *-general-private-* lookup does not apply.
      subnet_ids = module.cluster_vpc.private_subnets
      allowed_targets = [
        { cidr_block = local.vpc_cidr[local.cp_vpc_name].primary, port = 443 },
      ]
    }
  }

  tags = local.tags
}
