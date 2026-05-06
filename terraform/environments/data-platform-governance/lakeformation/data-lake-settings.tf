resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "5"
  }
}
