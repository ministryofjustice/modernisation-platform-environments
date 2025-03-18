resource "aws_lakeformation_permissions" "grant_account_table_filter" {
  count       = local.is-test ? 1 : 0
  principal   = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = "staged_fms_test_dbt"
    table_name       = "account"
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = module.share_current_version[0].data_filter_id[0]
  }
  permissions_with_grant_option = ["SELECT"]
}

resource "aws_lakeformation_permissions" "grant_account_table" {
  count       = local.is-test ? 1 : 0
  principal   = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions = ["DESCRIBE"]
  table {
    database_name = "staged_fms_test_dbt"
    name          = "account"
  }
  permissions_with_grant_option = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "grant_account_database" {
  count       = local.is-test ? 1 : 0
  principal   = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions = ["DESCRIBE"]
  database {
    name = "staged_fms_test_dbt"
  }
  permissions_with_grant_option = ["DESCRIBE"]
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_for_ap" {
  principal   = local.environment_management.account_ids["analytical-platform-data-production"]
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}
