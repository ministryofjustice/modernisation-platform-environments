locals {
  principals_to_share_with = [
    local.environment_management.account_ids["analytical-platform-data-production"],
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"
  ]
  tables_to_share_ap = {
    "derived": ["visits"],
  }
}

resource "aws_lakeformation_permissions" "share_cadt_bucket" {
  for_each = toset(local.principals_to_share_with)

  principal = each.value.principal
  permissions = ["DATA_LOCATION_ACCESS"]
  permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "share_table_with_ap" {
  for_each = {
    for pair in flatten([
      for principal in toset(local.principals_to_share_with) : [
        for database_name, tables in local.tables_to_share_ap : [
          for table_name in tables : {
            key = "${principal}:${database_name}.${table_name}"
            value = {
              database_name = database_name
              table_name    = table_name
              principal     = principal
            }
          }
        ]
      ]
    ]) : pair.key => pair.value
  }

  principal                     = each.value.principal
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]
  table {
    database_name = "${each.value.database_name}${local.dbt_suffix}"
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "share_database_with_ap" {
  for_each = {
    for pair in flatten([
      for principal in toset(local.principals_to_share_with) : [
        for database_name, tables in local.tables_to_share_ap : [
          for table_name in tables : {
            key = "${principal}:${database_name}.${table_name}"
            value = {
              database_name = database_name
              table_name    = table_name
              principal     = principal
            }
          }
        ]
      ]
    ]) : pair.key => pair.value
  }

  principal                     = each.value.principal
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]
  database {
    name = "${each.value.database_name}${local.dbt_suffix}"
  }
}
