locals {
  tables_to_optimize_flat = length(keys(data.external.glue_tables_by_database)) == 0 ? {} : merge([
    for database_name in keys(data.external.glue_tables_by_database) : {
      for table_name in try(jsondecode(data.external.glue_tables_by_database[database_name].result.tables_json), []) : "${database_name}.${table_name}" => merge(
        var.table_optimizer_defaults,
        {
          database_name       = database_name
          table_name          = table_name
          table_location      = lookup(
            try(jsondecode(data.external.glue_tables_by_database[database_name].result.locations_json), {}),
            table_name,
            null
          )
        }
      )
      if !contains(["test_results", "metrics"], database_name)
    }
  ]...)
}
