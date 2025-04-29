locals {
  tables_to_share_ap = {
    "derived": ["visits"],
  }
}

resource "aws_lakeformation_permissions" "share_cadt_bucket" {
  # provider = aws.eu_west_1
  principal = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions = ["DATA_LOCATION_ACCESS"]
  permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "share_table_with_ap" {
  # provider = aws.eu_west_1
  for_each                      = {for item in flatten([
    for database_name, tables in local.tables_to_share_ap : [
      for table_name in tables : {
        database_name = database_name
        table_name    = table_name
      }
    ]
  ]): "${item.database_name}.${item.table_name}" => item}
  principal                     = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]
  table {
    database_name = "${each.key}${local.dbt_suffix}"
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "share_database_with_ap" {
  # provider = aws.eu_west_1
  for_each                      = {for item in flatten([
    for database_name, tables in local.tables_to_share_ap : [
      for table_name in tables : {
        database_name = database_name
        table_name    = table_name
      }
    ]
  ]): "${item.database_name}.${item.table_name}" => item}
  principal                     = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]
  database {
    name = "${each.key}${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "share_data_cell_filter_with_ap" {
  # provider = aws.eu_west_1
  for_each                      = {for item in flatten([
    for database_name, tables in local.tables_to_share_ap : [
      for table_name in tables : {
        database_name = database_name
        table_name    = table_name
      }
    ]
  ]): "${item.database_name}.${item.table_name}" => item}
  principal                     = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions                   = ["SELECT"]
  permissions_with_grant_option = ["SELECT"]
  data_cells_filter {
    database_name    = "${each.key}${local.dbt_suffix}"
    name             =  "${each.value.table_name}_general_filter"
    table_catalog_id = data.aws_caller_identity.current.saccount_id
    table_name       = each.value.table_name
  }
}
