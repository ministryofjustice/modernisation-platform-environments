resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([[for role in aws_iam_role.analytical_platform_share_role : role.arn], data.aws_iam_session_context.current.issuer_arn])

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}