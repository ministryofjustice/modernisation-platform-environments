data "aws_caller_identity" "current" {}

resource "aws_lakeformation_permissions" "data_engineering_permissions" {
  for_each = toset(var.extra_arns)

  permissions = ["ALL"]
  principal   = each.value

  database {
    name = var.database_name
  }
}

resource "random_id" "suffix" {
  byte_length = 32
}

resource "aws_lakeformation_permissions" "data_engineering_table_permissions" {
  for_each = tomap({
    for pair in flatten([
      for arn in var.extra_arns : [
        for table, filter in var.table_filters : {
          key = "${arn}:${table}"
          value = {
            arn    = arn
            table  = table
            filter = filter
          }
        }
      ]
    ]) : pair.key => pair.value
  })
  permissions = ["ALL"]
  principal   = each.value.arn

  table {
    database_name = var.database_name
    name          = each.value.table
  }
}

resource "aws_lakeformation_permissions" "de_s3_bucket_permissions" {
  for_each = toset(var.extra_arns)

  permissions = ["DATA_LOCATION_ACCESS"]
  principal   = each.value
  data_location {
    arn = var.data_bucket_lf_resource
  }
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = var.role_arn

  permissions                   = ["DATA_LOCATION_ACCESS"]
  permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource
  }
}

resource "aws_lakeformation_data_cells_filter" "data_filter" {
  for_each = tomap(var.table_filters)
  table_data {
    database_name    = var.database_name
    name             = "filter-for-${var.role_arn}-${each.key}-${each.value != "" ? each.value : "all-rows"}"
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
  for_each                      = tomap(var.table_filters)
  principal                     = var.role_arn
  permissions                   = ["SELECT"]
  permissions_with_grant_option = ["SELECT"]
  data_cells_filter {
    database_name    = var.database_name
    table_name       = each.key
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.data_filter[each.key].table_data[0].name
  }
}

resource "aws_lakeformation_permissions" "share_table_with_role" {
  for_each                      = tomap(var.table_filters)
  principal                     = var.role_arn
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]
  table {
    database_name = var.database_name
    name          = each.key
  }
}
