resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [data.aws_iam_session_context.current.issuer_arn, module.lake_formation_share_role.iam_role_arn]

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}
