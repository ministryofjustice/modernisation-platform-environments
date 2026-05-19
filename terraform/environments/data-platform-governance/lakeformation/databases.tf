resource "aws_glue_catalog_database" "main" {
  for_each = tomap({
    for database in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for product_name, product in try(factory.products, {}) : {
          factory_name = factory_name
          domain       = factory.domain
          product      = product
          product_name = product_name
          name         = "${factory.domain}-${product_name}"
        }
      ]
    ]) : database.name => database
  })

  name         = each.value.name
  location_uri = "s3://moj-data-lake-${local.environment_management.account_ids[each.value.factory_name]}-${data.aws_region.current.region}-an/${each.value.domain}/${each.value.product_name}/"

  tags = merge(
    local.tags,
    {
      "justice-data-factory"          = each.value.factory_name
      "justice-data-lake-domain"      = each.value.domain
      "justice-data-platform-project" = each.value.product.project
    }
  )
}

resource "aws_lakeformation_permissions" "database" {
  for_each = tomap({
    for database in flatten([
      for factory_name, factory in try(local.lakeformation_configuration.factories, {}) : [
        for product_name, product in try(factory.products, {}) : {
          factory_name = factory_name
          domain       = factory.domain
          product      = product
          product_name = product_name
          name         = "${factory.domain}-${product_name}"
        }
      ]
    ]) : database.name => database
  })

  principal   = local.environment_management.account_ids[each.value.factory_name]
  permissions = ["DESCRIBE", "CREATE_TABLE"]

  database {
    name = aws_glue_catalog_database.main[each.key].name
  }
}
