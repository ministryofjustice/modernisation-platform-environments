module "transform_cross_account_access" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-transform-cross-account-access?ref=changes-3007"

  # Must match the central Transform workspace configuration
  workspace_name = "example-development-erp-modernization"
  hub_account_id = local.environment_management.account_ids["core-shared-services-production"]

  # The module generates and stores the external ID in Secrets Manager
  external_id_secret_name = "transform/${local.application_name}/external-id"

  # Optional: override if you prefer a different tag key/value convention
  transform_access_tag_key    = "transform_access"
  transform_access_tag_values = ["true"]

  # Mutating actions: restricted to resources with transform_access=true
  migration_scope_actions = [
    "ec2:RunInstances",
    "ec2:TerminateInstances",
    "rds:Create*",
    "rds:Modify*",
    "ecs:Create*",
    "ecs:Update*",
    "mgn:Create*",
    "mgn:Update*"
  ]

  # Read/list actions: allowed without resource-tag condition
  migration_scope_actions_without_tag_condition = [
    "ec2:Describe*",
    "rds:Describe*",
    "ecs:Describe*",
    "ecs:List*",
    "mgn:Describe*",
    "mgn:List*"
  ]

  application_name = local.application_name
  tags             = local.tags
}
