resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
    module.lake_formation_share_role.iam_role_arn,
    module.analytical_platform_ui_service_role.iam_role_arn
  ]
}
