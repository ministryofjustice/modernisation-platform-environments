# DMS Module to Provision TASK
module "dms_task" {
  source = "../../dms_s3_v2"

  enable_replication_task   = var.enable_replication_task
  name                      = var.name
  project_id                = var.project_id
  env                       = var.env
  dms_replication_instance  = var.dms_replication_instance
  migration_type            = var.migration_type
  replication_task_settings = var.replication_task_settings
  table_mappings            = var.table_mappings
  rename_rule_source_schema = var.rename_rule_source_schema
  rename_rule_output_space  = var.rename_rule_output_space
  dms_source_endpoint       = var.dms_source_endpoint
  dms_target_endpoint       = var.dms_target_endpoint
  short_name                = var.short_name

  tags = var.tags
}