locals {
  env_ = "${local.environment_shorthand}_"
}

resource "aws_lakeformation_data_cells_filter" "filter_fms_current" {
  table_data {
    database_name    = "staged_fms_${local.env_}dbt"
    name             = "filter-fms-current"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = "account"


    row_filter {
      filter_expression = "select * from account where __current=true"
    }
  }
}
