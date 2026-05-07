module "data_lake_storage" {
  count = local.environment == "development" ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-storage?ref=feat/data-lake-storage"

  governance_account_id         = local.environment_management.account_ids["data-platform-governance-development"]
  lakeformation_access_role_arn = "arn:aws:iam::${local.environment_management.account_ids["data-platform-governance-development"]}:role/lakeformation-access"

  depends_on = [module.data_lake_settings]
}
