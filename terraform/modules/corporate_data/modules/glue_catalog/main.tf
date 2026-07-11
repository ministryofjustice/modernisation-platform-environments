resource "aws_glue_catalog_database" "corporate_glue_database" {
  name        = var.database_name
  description = var.database_description
}

resource "aws_glue_catalog_table" "corporate_glue_table" {
  for_each = var.tables

  name          = each.key
  database_name = aws_glue_catalog_database.corporate_glue_database.name
  description   = try(each.value.description, null)

  table_type = "EXTERNAL_TABLE"

  parameters = merge(
    {
      EXTERNAL = "TRUE"
    },
    try(each.value.parameters, {})
  )

  storage_descriptor {
    location = each.value.s3_location

    input_format = try(
      each.value.input_format,
      "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    )

    output_format = try(
      each.value.output_format,
      "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    )

    ser_de_info {
      name = each.key

      serialization_library = try(
        each.value.serialization_library,
        "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      )

      parameters = {
        "serialization.format" = "1"
      }
    }

    dynamic "columns" {
      for_each = each.value.columns

      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = try(columns.value.comment, null)
      }
    }
  }

  dynamic "partition_keys" {
    for_each = try(each.value.partition_keys, [])

    content {
      name    = partition_keys.value.name
      type    = partition_keys.value.type
      comment = try(partition_keys.value.comment, null)
    }
  }
}