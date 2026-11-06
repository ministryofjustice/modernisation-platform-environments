# ------------------------------------------------------------------------------
# Observability Platform
#
# Creates the tenant-side resources required for the MoJ Observability Platform
# to read CloudWatch telemetry from the Electronic Monitoring Data account.
# ------------------------------------------------------------------------------

module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "9.9.9"

  observability_platform_account_id = (
    local.environment_management.account_ids[
      "observability-platform-production"
    ]
  )

  tags = local.tags
}