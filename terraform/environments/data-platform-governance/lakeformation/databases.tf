resource "aws_glue_catalog_database" "main" {
  for_each = tomap({
    for database in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for database_name, database in try(factory.databases, {}) : {
          factory_name  = factory_name
          domain        = factory.domain
          database      = database
          database_name = database_name
          name          = "${factory.domain}-${database_name}"
        }
      ]
    ]) : database.name => database
  })

  name         = each.value.name
  location_uri = "s3://moj-data-lake-${local.environment_management.account_ids[each.value.factory_name]}-${data.aws_region.current.region}-an/${each.value.domain}/${each.value.database_name}/"

  tags = merge(
    local.tags,
    {
      "justice-data-factory"          = each.value.factory_name
      "justice-data-lake-domain"      = each.value.domain
      "justice-data-lake-database"    = each.value.database_name
      "justice-data-platform-project" = each.value.database.project
    }
  )
}

resource "aws_lakeformation_permissions" "database" {
  for_each = tomap({
    for grant in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for database_name, database in try(factory.databases, {}) : [
          for principal_name, principal in try(database.principals, {}) : {
            factory_name  = factory_name
            domain        = factory.domain
            principal     = principal_name
            permissions   = try(principal.permissions, [])
            database      = database
            database_name = database_name
            name          = "${factory.domain}-${database_name}"
          }
        ]
      ]
    ]) : "${grant.name}-${grant.principal}" => grant
  })

  principal   = "arn:aws:iam::${local.environment_management.account_ids[each.value.factory_name]}:role/${each.value.principal}"
  permissions = each.value.permissions

  database {
    name = aws_glue_catalog_database.main[each.value.name].name
  }
}
