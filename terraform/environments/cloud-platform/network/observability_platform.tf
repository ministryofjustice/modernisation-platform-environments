# Apply the development Observability Platform PDC configuration and populate
# each account's token secret before deploying this network component.
module "observability_platform_tenant" {
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      # All twelve network workspaces must also have pdc_enabled in the development stack.
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
