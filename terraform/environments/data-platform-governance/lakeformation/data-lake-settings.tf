module "data_lake_settings" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-settings?ref=feat/data-lake-settings"

  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
  ]
}

moved {
  from = aws_lakeformation_data_lake_settings.main
  to   = module.data_lake_settings.aws_lakeformation_data_lake_settings.main
} 
