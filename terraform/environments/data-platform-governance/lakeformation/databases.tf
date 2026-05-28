# Create the database in Governance
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

# Share database with factory(self)
resource "aws_lakeformation_permissions" "share_database_self" {
  for_each = tomap({
    for grant in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for database_name, database in try(factory.databases, {}) : {
          factory_name  = factory_name
          domain        = factory.domain
          database_name = database_name
          name          = "${factory.domain}-${database_name}"
          permissions = distinct(flatten([
            for principal_name, principal in try(database.principals, {}) :
            try(principal.permissions.database, [])
          ]))
          } if length(distinct(flatten([
            for principal_name, principal in try(database.principals, {}) :
            try(principal.permissions.database, [])
        ]))) > 0
      ]
    ]) : grant.name => grant
  })

  principal                     = local.environment_management.account_ids[each.value.factory_name]
  permissions                   = each.value.permissions
  permissions_with_grant_option = each.value.permissions

  database {
    name = aws_glue_catalog_database.main[each.value.name].name
  }
}

# Share tables with factory(self)
resource "aws_lakeformation_permissions" "share_tables_self" {
  for_each = tomap({
    for grant in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for database_name, database in try(factory.databases, {}) : {
          factory_name  = factory_name
          database_name = "${factory.domain}-${database_name}"
          permissions = distinct(flatten([
            for principal_name, principal in try(database.principals, {}) :
            try(principal.permissions.tables, [])
          ]))
          } if length(distinct(flatten([
            for principal_name, principal in try(database.principals, {}) :
            try(principal.permissions.tables, [])
        ]))) > 0
      ]
    ]) : grant.database_name => grant
  })

  principal                     = local.environment_management.account_ids[each.value.factory_name]
  permissions                   = each.value.permissions
  permissions_with_grant_option = each.value.permissions

  table {
    database_name = aws_glue_catalog_database.main[each.value.database_name].name
    wildcard      = true
  }
}
