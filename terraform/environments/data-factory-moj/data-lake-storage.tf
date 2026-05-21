module "data_lake_storage" {
  count = local.environment == "development" ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-storage?ref=feat/data-lake-storage"

  data_platform_governance_account_id = local.environment_management.account_ids["data-platform-governance-development"]
  data_platform_account_id            = local.environment_management.account_ids["data-platform-development"]
}
