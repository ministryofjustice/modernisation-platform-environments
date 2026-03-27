resource "aws_athena_workgroup" "default" {
  name        = format("%s-default", local.env_account_id)
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}


resource "aws_athena_workgroup" "ears_sars" {
  name        = format("%s-ears-sars", local.env_account_id)
  description = "An Athena workgroup for EAR/SARs, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/ears_sars/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt" {
  name        = "create-a-derived-table"
  description = "An Athena workgroup for cadt, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt-historic-dev" {
  count       = local.is-production ? 1 : 0
  name        = "create-a-derived-table-historic-dev"
  description = "An Athena workgroup for cadt historic dev, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/historic_dev/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_glue_catalog_database" "ears_sars_audit_db" {
  count = local.is-development || local.is-preproduction ? 1 : 0  
  name = "ears_sars_audit"
}

resource "aws_glue_catalog_table" "ears_sars_audit_table" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  name          = "reports_requested"
  database_name = aws_glue_catalog_database.ears_sars_audit_db[0].name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"              = "json"
    "projection.enabled"          = "true"
    "projection._year.type"        = "integer"
    "projection._year.range"       = "2025,2040"
    "projection._month.type"       = "integer"
    "projection._month.range"      = "1,12"
    "projection._day.type"         = "integer"
    "projection._day.range"        = "1,31"
    
    "storage.location.template" = "s3://${module.s3-logging-bucket.bucket.id}/ears_sars/$${_year}/$${_month}/$${_day}/"
  }
  storage_descriptor {
    location      = "s3://${module.s3-logging-bucket.bucket.id}/ears_sars/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
   columns {
      name = "legacy_subject_id"
      type = "string"
    }
    columns {
      name = "legacy_order_id"
      type = "string"
    }
    columns {
      name = "priority"
      type = "string"
    }
    columns {
      name = "monitoring_requirement"
      type = "string"
    }
    columns {
      name = "request_types"
      type = "array<string>"
    }
    columns {
      name = "information_requested_from"
      type = "string"
    }
    columns {
      name = "information_requested_to"
      type = "string"
    }
    columns {
      name = "time_of_request"
      type = "string"
    }
  }
  partition_keys {
    name = "_year"
    type = "string"
  }
  partition_keys {
    name = "_month"
    type = "string"
  }
  partition_keys {
    name = "_day"
    type = "string"
  }
}