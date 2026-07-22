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
        location                             = each.value.table_location
      }
    }
  }

  type = "orphan_file_deletion"

}
