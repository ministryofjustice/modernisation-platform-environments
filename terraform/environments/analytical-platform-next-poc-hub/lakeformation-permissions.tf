# resource "aws_lakeformation_permissions" "catalog_describe" {
#   principal = module.user_jacobwoffenden_iam_role.arn
#   permissions = ["DESCRIBE"]

#   catalog {
#     # Grants DESCRIBE on the entire Data Catalog
#   }
# }

# resource "aws_lakeformation_permissions" "db_describe" {
#   principal   = module.user_jacobwoffenden_iam_role.arn
#   permissions = ["DESCRIBE"]

#   database {
#     name = "moj"
#     # catalog_id = data.aws_caller_identity.current.account_id
#     catalog_id = local.producer_account_id
#   }
# }

# resource "aws_lakeformation_permissions" "table_select_describe" {
#   principal   = module.user_jacobwoffenden_iam_role.arn
#   permissions = ["SELECT", "DESCRIBE"]

#   table {
#     database_name = "moj"
#     wildcard      = true
#     catalog_id    = local.producer_account_id
#   }
# }

resource "aws_lakeformation_permissions" "jacobwoffenden_database_resource_link" {
  principal                     = module.user_jacobwoffenden_iam_role.arn
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name       = "moj_resource_link"
    catalog_id = data.aws_caller_identity.current.account_id
  }
}

resource "aws_lakeformation_permissions" "jacobwoffenden_database" {
  principal                     = module.user_jacobwoffenden_iam_role.arn
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name       = "moj"
    catalog_id = local.producer_account_id
  }
}

resource "aws_lakeformation_permissions" "jacobwoffenden_database_tables" {
  principal                     = module.user_jacobwoffenden_iam_role.arn
  permissions                   = ["SELECT", "DESCRIBE"]
  permissions_with_grant_option = ["SELECT", "DESCRIBE"]

  table {
    database_name = "moj"
    wildcard      = true
    catalog_id    = local.producer_account_id
  }
}
