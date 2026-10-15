# Glue Permissions
resource "aws_iam_role" "glue" {
  name               = "glue-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json

  tags = { Name = "glue-${local.name}" }
}

data "aws_iam_policy_document" "glue_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${module.s3_bucket.bucket.arn}/${local.name}-access/AWSLogs/${var.account_id}/*",
      "${module.s3_bucket.bucket.arn}/${local.name}-connection/AWSLogs/${var.account_id}/*"
    ]
  }
}

resource "aws_iam_policy" "glue_s3" {
  name   = "glue-s3-${local.name}"
  policy = data.aws_iam_policy_document.glue_s3.json

  tags = { Name = "glue-s3-${local.name}" }
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_s3.arn
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Catalog Tables
resource "aws_glue_catalog_table" "alb_access_logs" {
  name          = "${local.name}-alb-access-logs"
  database_name = aws_athena_database.alb_logs.name

  table_type = "EXTERNAL_TABLE"

  partition_keys {
    name = "day"
    type = "string"
  }

  parameters = {
    "projection.enabled"           = "true"
    "projection.day.format"        = "yyyy/MM/dd"
    "projection.day.interval"      = "1"
    "projection.day.interval.unit" = "DAYS"
    "projection.day.type"          = "date"
    "projection.day.range"         = "2023/01/01,NOW"
    "storage.location.template"    = "s3://${module.s3_bucket.bucket.id}/${local.name}-access/AWSLogs/${var.account_id}/elasticloadbalancing/${var.account_region}/$${day}"
  }

  storage_descriptor {
    location      = "s3://${module.s3_bucket.bucket.id}/${local.name}-access/AWSLogs/${var.account_id}/elasticloadbalancing/${var.account_region}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name = "alb_access_logs"
      parameters = {
        "serialization.format" = "1",
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^s]+?)\" \"([^s]+)\" \"([^ ]*)\" \"([^ ]*)\" ([^ ]*)(?: ([^ ]+)){0,10}"
      }
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
    }
    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "elb"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "client_port"
      type = "int"
    }
    columns {
      name = "target_ip"
      type = "string"
    }
    columns {
      name = "target_port"
      type = "int"
    }
    columns {
      name = "request_processing_time"
      type = "double"
    }
    columns {
      name = "target_processing_time"
      type = "double"
    }
    columns {
      name = "response_processing_time"
      type = "double"
    }
    columns {
      name = "elb_status_code"
      type = "int"
    }
    columns {
      name = "target_status_code"
      type = "string"
    }
    columns {
      name = "received_bytes"
      type = "bigint"
    }
    columns {
      name = "sent_bytes"
      type = "bigint"
    }
    columns {
      name = "request_verb"
      type = "string"
    }
    columns {
      name = "request_url"
      type = "string"
    }
    columns {
      name = "request_proto"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "target_group_arn"
      type = "string"
    }
    columns {
      name = "trace_id"
      type = "string"
    }
    columns {
      name = "domain_name"
      type = "string"
    }
    columns {
      name = "chosen_cert_arn"
      type = "string"
    }
    columns {
      name = "matched_rule_priority"
      type = "string"
    }
    columns {
      name = "request_creation_time"
      type = "string"
    }
    columns {
      name = "actions_executed"
      type = "string"
    }
    columns {
      name = "redirect_url"
      type = "string"
    }
    columns {
      name = "lambda_error_reason"
      type = "string"
    }
    columns {
      name = "target_port_list"
      type = "string"
    }
    columns {
      name = "target_status_code_list"
      type = "string"
    }
    columns {
      name = "classification"
      type = "string"
    }
    columns {
      name = "classification_reason"
      type = "string"
    }
    columns {
      name = "conn_trace_id"
      type = "string"
    }
    columns {
      name = "transformed_host"
      type = "string"
    }
    columns {
      name = "transformed_uri"
      type = "string"
    }
    columns {
      name = "request_transform_status"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "alb_connection_logs" {
  name          = "${local.name}-alb-connection-logs"
  database_name = aws_athena_database.alb_logs.name
  table_type    = "EXTERNAL_TABLE"

  partition_keys {
    name = "day"
    type = "string"
  }

  parameters = {
    "projection.enabled"           = "true"
    "projection.day.format"        = "yyyy/MM/dd"
    "projection.day.interval"      = "1"
    "projection.day.interval.unit" = "DAYS"
    "projection.day.type"          = "date"
    "projection.day.range"         = "2023/01/01,NOW"
    "storage.location.template"    = "s3://${module.s3_bucket.bucket.id}/${local.name}-connection/AWSLogs/${var.account_id}/elasticloadbalancing/${var.account_region}/$${day}"
  }

  storage_descriptor {
    location      = "s3://${module.s3_bucket.bucket.id}/${local.name}-connection/AWSLogs/${var.account_id}/elasticloadbalancing/${var.account_region}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name = "alb_connection_logs"
      parameters = {
        "serialization.format" = "1"
        "input.regex"          = "([^ ]*) ([^ ]*) ([0-9]*) ([0-9]*) ([^ ]*) ([^ ]*) ([-.0-9]*) (\"[^\"]*\"|-) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)"
      }
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
    }

    columns {
      name = "time"
      type = "string"
    }

    columns {
      name = "client_ip"
      type = "string"
    }

    columns {
      name = "client_port"
      type = "int"
    }

    columns {
      name = "listener_port"
      type = "int"
    }

    columns {
      name = "tls_protocol"
      type = "string"
    }

    columns {
      name = "tls_cipher"
      type = "string"
    }

    columns {
      name = "tls_handshake_latency"
      type = "double"
    }

    columns {
      name = "leaf_client_cert_subject"
      type = "string"
    }

    columns {
      name = "leaf_client_cert_validity"
      type = "string"
    }

    columns {
      name = "leaf_client_cert_serial_number"
      type = "string"
    }

    columns {
      name = "tls_verify_status"
      type = "string"
    }

    columns {
      name = "conn_trace_id"
      type = "string"
    }

    columns {
      name = "tls_keyexchange"
      type = "string"
    }

    columns {
      name = "elb"
      type = "string"
    }

    columns {
      name = "ip_address"
      type = "string"
    }
  }
}
