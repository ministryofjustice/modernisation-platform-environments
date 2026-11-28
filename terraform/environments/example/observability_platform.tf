# Apply the central Example opt-in and confirm first-token issuance before deploying these agents.
module "observability_platform_tenant" {
  count = local.is-development ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      enabled = true
    }
  }

  tags = local.tags
}
