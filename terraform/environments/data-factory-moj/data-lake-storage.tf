module "data_lake_storage" {
  count = local.environment == "development" ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-storage?ref=feat/data-lake-storage"

  data_platform_governance_account_id = local.environment_management.account_ids["data-platform-governance-development"]
  data_platform_account_id            = local.environment_management.account_ids["data-platform-development"]
  dbt_access_trusted_role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
}
