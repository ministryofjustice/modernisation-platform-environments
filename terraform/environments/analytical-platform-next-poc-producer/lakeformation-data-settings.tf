resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess", # GitHub Actions
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}",
  ]

  // TODO
  trusted_resource_owners = [
    data.aws_caller_identity.current.account_id,
    local.hub_account_id
  ]
}
