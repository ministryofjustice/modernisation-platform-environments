module "data_lake_storage" {
  count = local.environment == "development" ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-storage?ref=feat/data-lake-storage"
}
