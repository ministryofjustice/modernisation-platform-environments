resource "aws_lakeformation_permissions" "data_engineer_access_db" {
  for_each = toset(local.environments[local.environment].lakeformation_admins)
  permissions = [
    "DESCRIBE",
    "CREATE_TABLE",
  ]
  principal = each.value

  database {
    name = "raw"
  }
}

resource "aws_lakeformation_permissions" "data_engineer_access_table" {
  for_each = toset(local.environments[local.environment].lakeformation_admins)
  permissions = [
    "SELECT",
    "DESCRIBE",
    "ALTER",
    "DROP",
    "INSERT",
    "DELETE"
  ]
  principal = each.value

  table {
    database_name = "raw"
    wildcard      = true
  }
}

#TODO: DELETE AFTER ACCESS DATA MOVED
resource "aws_lakeformation_permissions" "data_engineer_access_temp" {
  for_each = toset(local.environments[local.environment].lakeformation_admins)
  permissions = [
    "DESCRIBE"
  ]
  principal = each.value

  database {
    name = "data-factory-laa-access"
  }
}

resource "aws_lakeformation_permissions" "data_engineer_access_tables_temp" {
  for_each = toset(local.environments[local.environment].lakeformation_admins)
  permissions = [
    "SELECT",
    "DESCRIBE",
    "ALTER",
    "DROP",
    "INSERT",
    "DELETE"
  ]
  principal = each.value

  table {
    database_name = "data-factory-laa-access"
    wildcard      = true
  }
}
