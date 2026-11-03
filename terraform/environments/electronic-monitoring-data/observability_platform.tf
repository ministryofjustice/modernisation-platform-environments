# ------------------------------------------------------------------------------
# Observability Platform
#
# Creates the tenant-side resources required for the MoJ Observability Platform
# to read CloudWatch telemetry from the Electronic Monitoring Data account.
# ------------------------------------------------------------------------------

module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "2.0.0"

  observability_platform_account_id = (
    local.environment_management.account_ids[
      "observability-platform-production"
    ]
  )

  tags = local.tags
}