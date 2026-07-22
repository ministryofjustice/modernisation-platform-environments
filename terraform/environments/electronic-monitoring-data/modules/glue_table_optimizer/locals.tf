locals {
  default_domain_by_database = {
    for db in var.databases : db => db
  }

  domain_by_database = merge(
    local.default_domain_by_database,
    var.dbt_domain_name_by_database
  )

  raw_prefix_by_database = {
    for db in var.databases : db => "staging/${db}_pipeline/${db}"
  }

  dbt_suffix = var.environment == "prod" ? "" : "_${var.environment}_dbt"


  tables_to_optimize_flat = length(keys(data.external.glue_tables_by_database)) == 0 ? {} : merge([
    for database_name in keys(data.external.glue_tables_by_database) : {
      for table_name in try(jsondecode(data.external.glue_tables_by_database[database_name].result.tables_json), []) : "${database_name}.${table_name}" => merge(
        var.table_optimizer_defaults,
        {
          database_name       = database_name
          table_name          = table_name
          raw_database_prefix = lookup(local.raw_prefix_by_database, "${database_name}${local.dbt_suffix}", null)
          dbt_domain          = lookup(local.domain_by_database, "${database_name}${local.dbt_suffix}", null)
        }
      )
    }
  ]...)
}
