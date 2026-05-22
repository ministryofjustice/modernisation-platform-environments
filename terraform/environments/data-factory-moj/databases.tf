# resource "aws_glue_catalog_database" "main" {
#   for_each = tomap(try(local.data_platform_lakeformation_configuration.databases, {}))

#   name = "${local.data_platform_lakeformation_configuration.domain}-${each.key}"

#   target_database {
#     catalog_id    = local.environment_management.account_ids["data-platform-governance-${local.environment_configuration.data_lake_environment}"]
#     database_name = "${local.data_platform_lakeformation_configuration.domain}-${each.key}"
#   }

#   tags = merge(
#     local.tags,
#     {
#       "justice-data-factory"          = "${local.application_name}-${local.environment}"
#       "justice-data-lake-domain"      = local.data_platform_lakeformation_configuration.domain
#       "justice-data-lake-database"    = each.key
#       "justice-data-platform-project" = each.value.project
#     }
#   )
# }

# resource "aws_lakeformation_permissions" "database" {
#   for_each = tomap({
#     for grant in flatten([
#       for database_name, database in try(local.data_platform_lakeformation_configuration.databases, {}) : [
#         for principal_name, principal in try(database.principals, {}) : {
#           database_name = database_name
#           name          = database_name
#           permissions   = try(principal.permissions.resource_link, [])
#           principal     = principal_name
#         } if length(try(principal.permissions.resource_link, [])) > 0
#       ]
#     ]) : "${grant.name}-${grant.principal}" => grant
#   })

#   principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value.principal}"
#   permissions = each.value.permissions

#   database {
#     name = aws_glue_catalog_database.main[each.value.database_name].name
#   }
# }

## JW and JHP TESTING

resource "aws_glue_catalog_database" "test" {
  name = "test"
}

resource "aws_lakeformation_permissions" "share_database" {
  principal   = local.environment_management.account_ids["data-platform-governance-${local.environment_configuration.data_lake_environment}"]
  permissions = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.test.name
  }
}

resource "aws_lakeformation_permissions" "tables" {

  principal   = local.environment_management.account_ids["data-platform-governance-${local.environment_configuration.data_lake_environment}"]
  permissions = ["DESCRIBE", "SELECT"]

  table {
    database_name = aws_glue_catalog_database.test.name
    wildcard      = true
  }
}
