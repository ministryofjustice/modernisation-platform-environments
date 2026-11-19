# Observability Platform tenant, to test Grafana Cloud and PDC against the development stack.
# The PDC agent's token secret is created in observability-platform-development, so apply that first.
module "observability_platform_tenant" {
  # Only the development workspace exists for this account
  count = local.is-development ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=3b85e0a3e4f5b1f7a5df13f170a1a412633e11c9" # v3.0.0

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
