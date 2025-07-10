locals {
  databases_for_db_access = [
    "dpr_ap_integration_test_tag2_dev_dbt",
    "dpr_ap_integration_test_newtag_dev_dbt",
    "dpr_ap_integration_test_notag_dev_dbt"
  ]

  principals = [
    aws_iam_role.dataapi_cross_role.arn,
    "arn:aws:iam::771283872747:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_a2da3e45320e1580"
  ]
}

# Cartesian product: for each (database, principal) combination
locals {
  database_principal_pairs = {
    for pair in setproduct(local.databases_for_db_access, local.principals) :
    "${pair[0]}::${pair[1]}" => {
      database  = pair[0]
      principal = pair[1]
    }
  }
}

resource "aws_lakeformation_permissions" "role_db_access_internal" {
  for_each = local.database_principal_pairs

  principal   = each.value.principal
  permissions = ["ALL"]

  database {
    name = each.value.database
  }
}

resource "aws_lakeformation_permissions" "role_table_access_internal" {
  for_each = local.database_principal_pairs

  principal   = each.value.principal
  permissions = ["ALL"]

  table {
    database_name = each.value.database
    wildcard      = true
  }
}
