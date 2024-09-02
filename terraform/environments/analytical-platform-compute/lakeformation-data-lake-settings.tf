resource "aws_lakeformation_data_lake_settings" "london" {
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
    module.lake_formation_share_role.iam_role_arn,
    module.analytical_platform_ui_service_role.iam_role_arn
  ]
}

resource "aws_lakeformation_data_lake_settings" "ireland" {
  provider = aws.analytical-platform-compute-eu-west-1
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
    module.lake_formation_share_role.iam_role_arn,
    module.analytical_platform_ui_service_role.iam_role_arn
  ]
}
