module "athena_results_bucket" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=dd0c434de5e74d8864e249ee020d917b076b6e32" # v5.15.4

  bucket = "${local.bucket_name}-athena-results"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [{
    id     = "expire-query-results"
    status = "Enabled"
    expiration = {
      days = 30
    }
  }]
}

resource "aws_glue_catalog_database" "github_audit_logs" {
  count = local.is-production ? 1 : 0

  name        = "github_audit_logs"
  description = "GitHub Enterprise audit logs streamed to S3"
}

resource "aws_glue_catalog_table" "github_audit_logs" {
  count = local.is-production ? 1 : 0

  name          = "enterprise_audit_logs"
  database_name = aws_glue_catalog_database.github_audit_logs[0].name
  description   = "GitHub Enterprise audit events stored as compressed JSON"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"                          = "TRUE"
    "classification"                    = "json"
    "projection.enabled"                = "true"
    "projection.datehour.type"          = "date"
    "projection.datehour.range"         = "NOW-730DAYS,NOW"
    "projection.datehour.format"        = "yyyy/MM/dd/HH"
    "projection.datehour.interval"      = "1"
    "projection.datehour.interval.unit" = "HOURS"
    "storage.location.template"         = "s3://${module.s3_bucket[0].s3_bucket_id}/$${datehour}/"
  }

  partition_keys {
    name = "datehour"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${module.s3_bucket[0].s3_bucket_id}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    columns {
      name = "event_timestamp"
      type = "bigint"
    }
    columns {
      name = "action"
      type = "string"
    }
    columns {
      name = "actor"
      type = "string"
    }
    columns {
      name = "actor_id"
      type = "bigint"
    }
    columns {
      name = "user"
      type = "string"
    }
    columns {
      name = "user_id"
      type = "bigint"
    }
    columns {
      name = "org"
      type = "string"
    }
    columns {
      name = "repo"
      type = "string"
    }
    columns {
      name = "programmatic_access_type"
      type = "string"
    }

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "ignore.malformed.json"   = "true"
        "mapping.event_timestamp" = "@timestamp"
      }
    }
  }
}

resource "aws_athena_workgroup" "github_audit_logs" {
  count = local.is-production ? 1 : 0

  name        = "github-audit-logs"
  description = "Query GitHub Enterprise audit logs stored in S3"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 10737418240 # 10 GiB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_results_bucket[0].s3_bucket_id}/results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.kms_key[0].key_arn
      }

      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}
