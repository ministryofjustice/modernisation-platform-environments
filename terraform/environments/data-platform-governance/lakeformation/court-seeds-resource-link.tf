locals {
  court_seeds_database_name = "court_seeds"

  court_seeds_data_factory_account_id = local.environment_management.account_ids["data-factory-moj-${local.environment}"]
}

resource "aws_glue_catalog_database" "court_seeds" {
  name = local.court_seeds_database_name

  target_database {
    catalog_id    = local.court_seeds_data_factory_account_id
    database_name = local.court_seeds_database_name
  }

  tags = merge(
    local.tags,
    {
      "justice-data-factory"       = "data-factory-moj-${local.environment}"
      "justice-data-lake-database" = local.court_seeds_database_name
    }
  )
}
