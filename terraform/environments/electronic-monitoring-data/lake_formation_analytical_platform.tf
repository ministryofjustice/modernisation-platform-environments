resource "aws_lakeformation_permissions" "grant_test_databases" {
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = "staged_fms_test_dbt"
    table_name       = "account"
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = module.share_current_version[0].data_filter_id[0]
  }
}
