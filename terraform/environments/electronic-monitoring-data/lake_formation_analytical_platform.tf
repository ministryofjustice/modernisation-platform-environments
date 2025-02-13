resource "aws_lakeformation_permissions" "grant_account_table_filter" {
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

resource "aws_lakeformation_permissions" "grant_account_table" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"
  permissions = ["DESCRIBE"]
  table {
    database_name = "staged_fms_test_dbt"
    name          = "account"
  }
}

resource "aws_lakeformation_permissions" "grant_account_database" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"
  permissions = ["DESCRIBE"]
  database {
    name = "staged_fms_test_dbt"
  }
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_for_ap" {
  principal = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_matt-heery"

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}


resource "aws_lakeformation_permissions" "grant_account_table_filter_de" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_48361bdb022cb721"
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = "staged_fms_test_dbt"
    table_name       = "account"
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = module.share_current_version[0].data_filter_id[0]
  }
}

resource "aws_lakeformation_permissions" "grant_account_table_de" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_48361bdb022cb721"
  permissions = ["DESCRIBE"]
  table {
    database_name = "staged_fms_test_dbt"
    name          = "account"
  }
}

resource "aws_lakeformation_permissions" "grant_account_database_de" {
  count       = local.is-test ? 1 : 0
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_48361bdb022cb721"
  permissions = ["DESCRIBE"]
  database {
    name = "staged_fms_test_dbt"
  }
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_for_ap_de" {
  principal = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_48361bdb022cb721"

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}
