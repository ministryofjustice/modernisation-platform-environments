resource "aws_lakeformation_data_lake_settings" "london" {
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
    module.lake_formation_share_role.iam_role_arn,
    module.analytical_platform_ui_service_role.iam_role_arn,
    module.analytical_platform_data_eng_dba_service_role.iam_role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}"
  ]
}

resource "aws_lakeformation_data_lake_settings" "ireland" {
  provider = aws.analytical-platform-compute-eu-west-1
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
    module.lake_formation_share_role.iam_role_arn,
    module.analytical_platform_ui_service_role.iam_role_arn,
    module.analytical_platform_data_eng_dba_service_role.iam_role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}"
  ]
}
