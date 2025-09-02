# # Required Lake Formation permissions to query shared Glue database
# resource "aws_lakeformation_permissions" "jacobwoffenden_database_resource_link" {
#   principal                     = module.user_jacobwoffenden_iam_role.arn
#   permissions                   = ["DESCRIBE"]
#   permissions_with_grant_option = ["DESCRIBE"]

#   database {
#     catalog_id = data.aws_caller_identity.current.account_id
#     name       = aws_glue_catalog_database.producer_resource_link.name
#   }
# }

# resource "aws_lakeformation_permissions" "jacobwoffenden_database" {
#   principal                     = module.user_jacobwoffenden_iam_role.arn
#   permissions                   = ["DESCRIBE"]
#   permissions_with_grant_option = ["DESCRIBE"]

#   database {
#     catalog_id = local.producer_account_id
#     name       = local.producer_database
#   }
# }

# resource "aws_lakeformation_permissions" "jacobwoffenden_database_tables" {
#   principal                     = module.user_jacobwoffenden_iam_role.arn
#   permissions                   = ["SELECT", "DESCRIBE"]
#   permissions_with_grant_option = ["SELECT", "DESCRIBE"]

#   table {
#     catalog_id    = local.producer_account_id
#     database_name = local.producer_database
#     wildcard      = true
#   }
# }
