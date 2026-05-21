resource "aws_glue_catalog_database" "main" {
  for_each = tomap(try(local.data_platform_lakeformation_configuration.databases, {}))

  name = each.key

  target_database {
    catalog_id    = local.environment_management.account_ids["data-platform-governance-${local.environment_configuration.data_lake_environment}"]
    database_name = each.key
  }

  tags = merge(
    local.tags,
    {
      "justice-data-factory"          = "${local.application_name}-${local.environment}"
      "justice-data-lake-domain"      = local.data_platform_lakeformation_configuration.domain
      "justice-data-lake-database"    = each.key
      "justice-data-platform-project" = each.value.project
    }
  )
}

resource "aws_lakeformation_permissions" "database" {
  for_each = tomap({
    for grant in flatten([
      for database_name, database in try(local.data_platform_lakeformation_configuration.databases, {}) : [
        for principal_name, principal in try(database.principals, {}) : {
          database_name = database_name
          name          = "${local.data_platform_lakeformation_configuration.domain}-${database_name}"
          permissions   = try(principal.permissions, [])
          principal     = principal_name
        }
      ]
    ]) : "${grant.name}-${grant.principal}" => grant
  })

  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value.principal}"
  permissions = each.value.permissions

  database {
    name = aws_glue_catalog_database.main[each.value.database_name].name
  }
}
