data "aws_caller_identity" "current" {}

resource "aws_lakeformation_resource" "data_location" {
  for_each                = { for idx, loc in var.data_locations : loc.data_location => loc }
  arn                     = each.value.data_location
  use_service_linked_role = true
}

resource "aws_lakeformation_permissions" "data_location_share" {
  for_each  = { for idx, loc in var.data_locations : loc.data_location => loc }
  principal = var.destination_account_id

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = each.value.data_location
  }
}


resource "aws_lakeformation_data_cells_filter" "data_filter" {
  for_each = {
    for db in var.databases_to_share : db.name => db
  }
  table_data {
    database_name    = each.value.source_database
    name             = "filter-${each.value.source_table}"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = each.value.source_table
    column_wildcard {
      excluded_column_names = each.value.excluded_columns ? each.value.excluded_columns : []
    }
    dynamic "row_filter" {
      for_each = each.value.row_filter != "" ? [each.value.row_filter] : []
      content {
        filter_expression = each.value.row_filter
      }
    }
    dynamic "row_filter" {
      for_each = each.value.row_filter == "" ? [each.value.row_filter] : []
      content {
        all_rows_wildcard {}
      }
    }
  }
}

resource "aws_lakeformation_permissions" "share_filtered_data" {
  for_each = {
    for db in var.databases_to_share : db.name => db
  }
  permissions = each.value.permissions
  principal   = var.destination_account_id

  data_cells_filter {
    database_name    = each.value.source_database
    table_name       = each.value.source_table
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.data_filter[each.key].table_data[0].name
  }
}
