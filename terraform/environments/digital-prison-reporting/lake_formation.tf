resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([[for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share].arn], data.aws_iam_session_context.current.issuer_arn])

  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_data_lake_settings#principal
  create_database_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}