locals {
  env_ = "${local.environment_shorthand}_"
}

resource "aws_lakeformation_resource" "cadt_bucket" {
  arn = module.s3-create-a-derived-table-bucket.bucket.arn
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = module.cmt_front_end_assumable_role.iam_role_arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.cadt_bucket.arn
  }
}

resource "aws_lakeformation_data_cells_filter" "filter_fms_current" {
  count = local.is-development ? 0 : 1
  table_data {
    database_name    = "staged_fms_${local.env_}dbt"
    name             = "filter-fms-current"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = "account"
    column_wildcard {
      excluded_column_names = ["__deleted"]
    }

    row_filter {
      filter_expression = "__current=true;"
    }
  }
}


resource "aws_lakeformation_permissions" "share_fms_with_cp" {
  count       = local.is-development ? 0 : 1
  principal   = module.cmt_front_end_assumable_role.iam_role_arn
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = "staged_fms_${local.env_}dbt"
    table_name       = "account"
    table_catalog_id = data.aws_caller_identity.current.account_id
    name             = aws_lakeformation_data_cells_filter.filter_fms_current[count.index].table_data[0].name
  }
}
