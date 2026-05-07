locals {
    read_only_dbs = [
        "acquisitive_crime",
        "data_insights",
    ]
}

data "aws_iam_roles" "mp_data_scientist" {
  name_regex  = "AWSReservedSSO_mp-data-scientist_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_permissions" "data_scientist_test_db_permissions" {
  count     = local.is-test ? 1 : 0
  principal = one(data.aws_iam_roles.mp_data_scientist.arns)

  database {
    name = "curated_fms_test_dbt"
  }

  permissions = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "data_scientist_test_table_permissions" {
  count     = local.is-test ? 1 : 0
  principal = one(data.aws_iam_roles.mp_data_scientist.arns)

  table {
    database_name = "curated_fms_test_dbt"
    wildcard      = true
  }

  permissions = ["SELECT", "DESCRIBE"]
}


resource "aws_lakeformation_permissions" "data_scientist_db_permissions" {
  for_each = local.is-preproduction ? toset(local.read_only_dbs) : []
  principal = one(data.aws_iam_roles.mp_data_scientist.arns)

  database {
    name = "${each.key}${local.dbt_suffix}"
  }

  permissions = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "data_scientist_table_permissions" {
  count     = local.is-preproduction ? toset(local.read_only_dbs) : []
  principal = one(data.aws_iam_roles.mp_data_scientist.arns)

  table {
    database_name = "${each.key}${local.dbt_suffix}"
    wildcard      = true
  }

  permissions = ["SELECT", "DESCRIBE"]
}
