data "aws_caller_identity" "current" {}

resource "aws_lakeformation_permissions" "data_engineering_permissions" {
  permissions = ["ALL"]
  principal   = var.data_engineer_role_arn

  database {
    name = var.database_name
  }
}

resource "random_id" "suffix" {
  byte_length = 32
}

resource "aws_lakeformation_permissions" "data_engineering_table_permissions" {
  for_each    = var.table_filters
  permissions = ["ALL"]
  principal   = var.data_engineer_role_arn

  table {
    database_name = var.database_name
    name          = each.key
  }
}

resource "aws_lakeformation_permissions" "de_s3_bucket_permissions" {
  principal = var.data_engineer_role_arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource
  }
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = var.role_arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource
  }
}

resource "aws_lakeformation_data_cells_filter" "data_filter" {
  for_each = tomap(var.table_filters)
  table_data {
    database_name    = var.database_name
    name             = "filter-${each.key}-${random_id.suffix.hex}"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = each.key
    column_wildcard {
      excluded_column_names = []
    }
    dynamic "row_filter" {
      for_each = each.value != "" ? [each.value] : []
      content {
        filter_expression = each.value
      }
    }
    dynamic "row_filter" {
      for_each = each.value == "" ? [each.value] : []
      content {
        all_rows_wildcard {}
      }
    }
  }
}

resource "aws_lakeformation_permissions" "share_filtered_data_with_role" {
  for_each    = tomap(var.table_filters)
  principal   = var.role_arn
  permissions = ["DESCRIBE", "SELECT"]
  data_cells_filter {
    database_name    = var.database_name
    table_name       = each.key
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.data_filter[each.key].table_data[0].name
  }
}
