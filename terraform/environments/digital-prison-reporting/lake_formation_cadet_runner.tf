resource "aws_lakeformation_permissions" "dataapi_cross_role_db_access" {
  for_each = toset([
    "dpr_ap_integration_test_tag2_dev_dbt",
    "dpr_ap_integration_test_newtag_dev_dbt"
  ])

  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["ALL"]

  database {
    name = each.key
  }
}

resource "aws_lakeformation_permissions" "dataapi_cross_role_table_access" {
  for_each = toset([
    "dpr_ap_integration_test_tag2_dev_dbt",
    "dpr_ap_integration_test_newtag_dev_dbt"
  ])

  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["ALL"]

  table {
    database_name = each.key
    wildcard      = true
  }
}