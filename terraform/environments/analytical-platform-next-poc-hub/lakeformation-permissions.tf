# # # Required Lake Formation permissions to query shared Glue database
# resource "aws_lakeformation_permissions" "jacobwoffenden_database_resource_link" {
#   #   principal                     = module.user_jacobwoffenden_iam_role.arn
#   principal                     = "arn:aws:iam::112639118718:role/users/jacobwoffenden"
#   permissions                   = ["DESCRIBE"]
#   permissions_with_grant_option = ["DESCRIBE"]

#   database {
#     catalog_id = data.aws_caller_identity.current.account_id
#     # name       = aws_glue_catalog_database.producer_resource_link.name
#     name = "720819236209_individual_db"
#   }
# }

# resource "aws_lakeformation_permissions" "jacobwoffenden_database" {
#   #   principal                     = module.user_jacobwoffenden_iam_role.arn
#   principal                     = "arn:aws:iam::112639118718:role/users/jacobwoffenden"
#   permissions                   = ["DESCRIBE"]
#   permissions_with_grant_option = ["DESCRIBE"]

#   database {
#     catalog_id = local.producer_account_id
#     # name       = local.producer_database
#     name = "individual_db"
#   }
# }

# resource "aws_lakeformation_permissions" "jacobwoffenden_database_tables" {
#   #   principal                     = module.user_jacobwoffenden_iam_role.arn
#   principal                     = "arn:aws:iam::112639118718:role/users/jacobwoffenden"
#   permissions                   = ["SELECT", "DESCRIBE"]
#   permissions_with_grant_option = ["SELECT", "DESCRIBE"]

#   table {
#     catalog_id = local.producer_account_id
#     # database_name = local.producer_database
#     database_name = "individual_db"
#     # wildcard      = true
#     name = "shared_tbl"
#   }
# }
