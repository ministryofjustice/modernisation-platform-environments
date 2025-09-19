resource "aws_glue_catalog_database" "main" {
  name = "${local.producer_account_id}_jacobtestdb"
}

resource "aws_glue_catalog_table" "main_shared_tbl" {
  name          = "shared_tbl"
  database_name = aws_glue_catalog_database.main.name

  target_table {
    catalog_id    = local.producer_account_id
    database_name = "individual_db"
    name          = "shared_tbl"
  }
  lifecycle {
    /* These are defined in the source table and Terraform tries to remove them */
    ignore_changes = [
      owner,
      parameters,
      table_type,
      storage_descriptor
    ]
  }
}
