resource "aws_glue_catalog_database" "this" {
  count = var.audit_main_account ? 1 : 0
  name  = "audit-db"
}

resource "aws_glue_catalog_table" "this" {
  count = var.audit_main_account ? 1 : 0

  database_name = aws_glue_catalog_database.this[0].name
  name          = "audit"
  description   = "table containing the audit data stored in S3"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${module.s3_bucket_oracledb_audit.bucket.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "s3-stream"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "DATE_TIME"
      type = "string"
    }

    columns {
      name = "OUTCOME"
      type = "string"
    }

    columns {
      name = "INTERACTION_PARAMETERS"
      type = "string"

    }

    columns {
      name = "USER_ID"
      type = "string"
    }
    columns {
      name = "USER_ID"
      type = "string"
    }

    columns {
      name = "SPG_USERNAME"
      type = "string"
    }

    columns {
      name = "CLIENT_DB"
      type = "string"
    }

    columns {
      name = "CLIENT_BUSINESS_INTERACT_CODE"
      type = "string"
    }

  }
}
