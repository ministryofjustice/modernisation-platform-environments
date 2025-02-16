# locals {
#   # this is very nearly the same as what we do in glue-database, should be a way to rationalise
#
#   db_meta = { for db, meta in var.databases : db =>
#       merge(jsondecode(file("metadata/${meta.table_mappings.metadata_file}")),
#             {schema = meta.table_mappings.schema})
#   }
#
#   tables_meta = {
#     for db, meta in local.db_meta : db => {
#       for table in meta.objects : "${db}.${table}" => {
#         name = table
#         formatted_name = lower(replace(table, "-", "_"))
#         schema = meta.schema
#       }
#     }
#   }
#
#   include_tables = {
#     for db, tables in local.tables_meta : db => [
#       for table, meta in tables :
#         {
#           rule-type = "selection"
#           rule-name = "include-${meta.formatted_name}"
#           object-locator = {
#             schema-name = meta.schema
#             table-name = meta.name
#           }
#           rule-action = "explicit"
#         }
#     ]
#   }
#
#   add_scn_column = {
#     for db, tables in local.tables_meta : db => [
#       for table, meta in tables :
#         {
#           rule-type = "transformation"
#           rule-name = "add-scn-${meta.formatted_name}"
#           rule-target = "column"
#           object-locator = {
#             schema-name = meta.schema
#             table-name = meta.name
#           }
#           rule-action = "add-column"
#           value = "SCN"
#           expression = "$AR_H_STREAM_POSITION"
#           data-type = {
#             type = "string"
#             length = 50
#           }
#         }
#     ]
#   }
#
#   exclude_blobs = {
#     for db, meta in local.db_meta : db => [
#       for blob in meta.blobs :
#       {
#         rule-type = "transformation"
#         # would be nice if we didn't need to do this formatting...
#         rule-name = "remove-${lower(replace(blob.column_name, "-", "_"))}-from-${lower(replace(blob.object_name, "-", "_"))}"
#         rule-action = "remove-column"
#         rule-target = "column"
#         object-locator = {
#             schema-name = meta.schema
#             table-name = blob.object_name
#             column-name = blob.column_name
#         }
#       }
#     ]
#   }
#
#   rename_mat_views = {
#     for db, tables in local.tables_meta : db => [
#       for table, meta in tables :
#         {
#           rule-type = "transformation"
#           rule-name = "rename-${meta.formatted_name}"
#           rule-target = "table"
#           object-locator = {
#               schema-name = meta.schema
#               table-name = meta.name
#           }
#           rule-action = "rename"
#           value = replace(meta.name, "_MV", "")
#         }
#         if endswith(meta.name, "_MV")
#     ]
#   }
#
#   table_mappings = {
#     for db, _ in var.databases : db => [
#       for idx, rule in concat(
#         local.include_tables[db],
#         local.add_scn_column[db],
#         local.exclude_blobs[db],
#         local.rename_mat_views[db]
#       ) : merge({rule-id = idx + 1}, rule)
#     ]
#   }
# }
