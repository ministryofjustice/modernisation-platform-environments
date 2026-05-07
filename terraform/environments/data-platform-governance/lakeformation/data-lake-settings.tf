module "data_lake_settings" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-settings?ref=feat/data-lake-storage"

  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
  ]

  trusted_resource_owners = [
    local.environment_management.account_ids["data-platform-governance-development"]
  ]
}
