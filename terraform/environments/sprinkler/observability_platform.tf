# Observability Platform tenant, pre-release, to test Grafana Cloud and PDC against the development stack.
# The PDC agent's token secret is created in observability-platform-development, so apply that first.
module "observability_platform_tenant" {
  # Only the development workspace exists for this account
  count = local.is-development ? 1 : 0

  # Draft ministryofjustice/terraform-aws-observability-platform-tenant#126
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=b92afb7f5f78c9c4d5e6db10c2ea5e1a18a8e3e2"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    # Opt in, matching pdc_enabled in Observability Platform's Grafana Cloud tenant configuration
    pdc_agent = {
      enabled = true
    }
  }

  tags = local.tags
}
