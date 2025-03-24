data "aws_caller_identity" "current" {}

resource "aws_lakeformation_data_cells_filter" "data_filter" {
  table_data {
    database_name    = var.database_name
    name             = "filter-${var.table_name}"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = var.table_name
    column_wildcard {
      excluded_column_names = []
    }
    row_filter {
      filter_expression = var.table_filter
    }
  }
}


resource "aws_lakeformation_permissions" "grant_account_table_filter_role" {
  principal   = var.destination_account_role_arn
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = var.database_name
    table_name       = var.table_name
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.data_filter.table_data[0].name
  }
}

resource "aws_lakeformation_permissions" "grant_account_table_filter" {
  principal   = var.destination_account_id
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = var.database_name
    table_name       = var.table_name
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.data_filter.table_data[0].name
  }
  permissions_with_grant_option = ["SELECT"]
}

resource "aws_lakeformation_permissions" "grant_account_table" {
  principal   = var.destination_account_id
  permissions = ["DESCRIBE"]
  table {
    database_name = var.database_name
    name          = var.table_name
  }
  permissions_with_grant_option = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "grant_account_database" {
  principal   = var.destination_account_id
  permissions = ["DESCRIBE"]
  database {
    name = var.database_name
  }
  permissions_with_grant_option = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_for_ap" {
  principal   = var.destination_account_id
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_arn
  }
}
