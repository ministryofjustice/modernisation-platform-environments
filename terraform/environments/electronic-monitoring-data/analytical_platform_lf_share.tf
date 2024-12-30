locals {
  data_locations = [
    {
      data_location = module.s3-create-a-derived-table-bucket.bucket.arn
      hybrid_access = true
      register      = true
      share         = true

    }
  ]

  databases_to_share = [
    {
      source_database = "staged_fms${local.env_}_dbt"
      source_table    = "account"
      permissions     = ["DESCRIBE", "SELECT"]
      row_filter      = "__current=true"

    }
  ]

  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}

module "analytical_platform_lf_share" {
  source = "./modules/analytical-platform-lakeformation"

  destination_account_id = local.environment_management.account_ids["analytical-platform-data-production"]

  data_locations = local.data_locations

  databases_to_share = local.databases_to_share
}
