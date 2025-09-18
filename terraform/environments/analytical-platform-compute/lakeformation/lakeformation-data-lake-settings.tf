resource "aws_lakeformation_data_lake_settings" "london" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
    module.lake_formation_share_role.iam_role_arn,
    # module.analytical_platform_ui_service_role.iam_role_arn,
    module.analytical_platform_data_eng_dba_service_role.iam_role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.eks_sso_access_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}",
    module.copy_apdp_cadet_metadata_to_compute_assumable_role.iam_role_arn
  ]
}

resource "aws_lakeformation_data_lake_settings" "ireland" {
  provider = aws.analytical-platform-compute-eu-west-1
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
    module.lake_formation_share_role.iam_role_arn,
    # module.analytical_platform_ui_service_role.iam_role_arn,
    module.analytical_platform_data_eng_dba_service_role.iam_role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.eks_sso_access_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}",
  ]
}
