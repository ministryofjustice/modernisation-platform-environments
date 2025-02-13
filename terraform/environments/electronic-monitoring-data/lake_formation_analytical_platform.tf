resource "aws_lakeformation_permissions" "grant_test_databases" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = "staged_fms_test_dbt"
    table_name       = "account"
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = module.share_current_version[0].data_filter_id[0]
  }
}

resource "aws_lakeformation_permissions" "grant_test_databases" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"
  permissions = ["DESCRIBE"]
  table {
    database_name = "staged_fms_test_dbt"
    name          = "account"
  }
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}
