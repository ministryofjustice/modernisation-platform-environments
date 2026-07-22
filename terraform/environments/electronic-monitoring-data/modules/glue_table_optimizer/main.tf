resource "aws_glue_catalog_table_optimizer" "standard_compaction" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = each.value.database_name
  table_name    = each.value.table_name

  configuration {
    role_arn = var.role_arn
    enabled  = true
  }

  type = "compaction"
}

resource "aws_glue_catalog_table_optimizer" "standard_retention" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = each.value.database_name
  table_name    = each.value.table_name

  configuration {
    role_arn = var.role_arn
    enabled  = true

    retention_configuration {
      iceberg_configuration {
        snapshot_retention_period_in_days = each.value.snapshot_retention_period_in_days
        number_of_snapshots_to_retain     = each.value.number_of_snapshots_to_retain
        clean_expired_files               = true
        run_rate_in_hours                 = each.value.retention_run_rate_in_hours
      }
    }
  }

  type = "retention"
}

resource "aws_glue_catalog_table_optimizer" "standard_orphan_file_deletion" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = each.value.database_name
  table_name    = each.value.table_name

  configuration {
    role_arn = var.role_arn
    enabled  = true

    orphan_file_deletion_configuration {
      iceberg_configuration {
        orphan_file_retention_period_in_days = each.value.orphan_file_retention_period_in_days
        run_rate_in_hours                    = each.value.orphan_file_deletion_run_rate_in_hours
        location                             = contains(var.dbt_databases, each.value.database_name) ? "s3://${var.optimizer_bucket_id}/data/${var.environment}/models/domain_name=${each.value.dbt_domain}/database_name=${each.value.database_name}/table_name=${each.value.table_name}/" : "s3://${var.optimizer_bucket_id}/${each.value.raw_database_prefix}/${each.value.table_name}/"
      }
    }
  }

  type = "orphan_file_deletion"
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_permissions" {
  principal   = var.role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource_arn
  }
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_table_permissions" {
  for_each    = var.databases
  principal   = var.role_arn
  permissions = ["ALTER", "DESCRIBE", "INSERT", "DELETE"]

  table {
    database_name = each.key
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_database_permissions" {
  for_each    = var.databases
  principal   = var.role_arn
  permissions = ["DESCRIBE"]

  database {
    name = each.key
  }
}
