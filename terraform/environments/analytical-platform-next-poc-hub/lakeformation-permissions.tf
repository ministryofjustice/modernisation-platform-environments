resource "aws_lakeformation_permissions" "example_database_share" {
  # principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  principal   = "arn:aws:iam::720819236209:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_platform-engineer-admin_2e5e9e783493542b"
  permissions = ["DESCRIBE"]

  database {
    name = "example_database"
  }
}

resource "aws_lakeformation_permissions" "share_example_db_example_table" {
  # principal                     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  principal = "arn:aws:iam::720819236209:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_platform-engineer-admin_2e5e9e783493542b"

  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "example_database"
    name          = "test_table"
  }
}
