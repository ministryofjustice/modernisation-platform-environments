locals {
    quicksight_users = ["matt.heery", "matthew.rixson", "khristiania.raihan", "lucy.astleyjones"]
    quicksight_dbs   = ["validation", "metrics", "check"]
    quicksight_user_db_map = merge([
        for user in local.quicksight_users : {
        for db in local.quicksight_dbs :
        "${user}.${db}" => {
            email    = user
            database = db
        }
        }
    ]...)
}

resource "aws_lakeformation_permissions" "quicksight_db_share" {
  for_each = local.quicksight_user_db_map
  principal = "arn:aws:quicksight:eu-west-2:${local.environment_management.account_ids["analytical-platform-compute-production"]}:user/default/${each.value.email}@justice.gov.uk"
  permissions = ["DESCRIBE"]
  database {
    name = each.value.database
  }
}

resource "aws_lakeformation_permissions" "quicksight_table_share" {
  for_each = local.quicksight_user_db_map
  principal = "arn:aws:quicksight:eu-west-2:${local.environment_management.account_ids["analytical-platform-compute-production"]}:user/default/${each.value.email}@justice.gov.uk"
  permissions = ["DESCRIBE", "SELECT"]

  table {
    database_name = each.value.database
    wildcard      = true
  }
}
