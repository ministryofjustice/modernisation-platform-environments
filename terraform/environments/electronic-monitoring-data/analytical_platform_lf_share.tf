locals {
  data_locations = [
    {
      data_location = module.s3-create-a-derived-table-bucket.bucket.arn
      hybrid_access = true
      register      = true
      share         = true

    }
  ]

  databases = [
    {
      source_database  = "staged_fms_${local.env_}dbt"
      source_table     = "account"
      permissions      = ["DESCRIBE", "SELECT"]
      row_filter       = "__current=true"
      excluded_columns = []
    }
  ]
}

module "analytical_platform_lf_share" {
  count  = local.is-test ? 1 : 0
  source = "./modules/analytical-platform-lakeformation"

  destination_account_id = local.environment_management.account_ids["analytical-platform-data-production"]

  data_locations = local.data_locations

  databases_to_share = local.databases
}
