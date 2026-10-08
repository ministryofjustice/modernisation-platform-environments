resource "aws_athena_database" "alb_logs" {
  name   = "alb_logs"
  bucket = aws_s3_bucket.alb_logs.id

  properties = {
    "classification" = "log"
  }
}

resource "aws_athena_workgroup" "lb_access_logs" {
  count = var.access_logs ? 1 : 0
  name  = "${var.application_name}-lb-access-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    result_configuration {
      output_location = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/output/" : "s3://${module.s3-bucket[0].bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-lb-access-logs"
    },
  )
}

# Glue Permissions
resource "aws_iam_role" "glue" {
  count              = var.access_logs ? 1 : 0
  name               = "glue-${var.application_name}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume[count.index].json

  tags = merge(var.tags, {
    Name = "glue-${var.application_name}"
  })
}

data "aws_iam_policy_document" "glue_assume" {
  count = var.access_logs ? 1 : 0
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
  count = var.access_logs ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = flatten([var.existing_bucket_name != ""
      ? [
        "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*",
        "arn:aws:s3:::${var.existing_bucket_name}/AWSLogs/${var.account_number}/*"
      ]
      : [
        "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*",
        "${module.s3-bucket[0].bucket.arn}/AWSLogs/${var.account_number}/*"
      ]
    ])
  }
}

resource "aws_iam_policy" "glue_s3" {
  count  = var.access_logs && length(data.aws_iam_policy_document.glue_s3) > 0 ? 1 : 0
  name   = "glue-s3-${var.application_name}"
  policy = data.aws_iam_policy_document.glue_s3[count.index].json

  tags = merge(var.tags, {
    Name = "glue-s3-${var.application_name}"
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  count      = var.access_logs && length(data.aws_iam_policy_document.glue_s3) > 0 ? 1 : 0
  role       = aws_iam_role.glue[count.index].name
  policy_arn = aws_iam_policy.glue_s3[count.index].arn
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  count      = var.access_logs ? 1 : 0
  role       = aws_iam_role.glue[count.index].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Catalog Tables
resource "aws_glue_catalog_table" "application_lb_logs" {
  count         = var.access_logs && var.load_balancer_type == "application" ? 1 : 0
  name          = "${var.application_name}-application-lb-logs"
  database_name = aws_athena_database.lb_access_logs[0].name

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
    "storage.location.template"    = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}/$${day}" : "s3://${module.s3-bucket[0].bucket.id}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}/$${day}"
  }
  storage_descriptor {
    location      = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}/" : "s3://${module.s3-bucket[0].bucket.id}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name = "application_lb_logs"
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

resource "aws_glue_catalog_table" "network_lb_logs" {
  count         = var.access_logs && var.load_balancer_type == "network" ? 1 : 0
  name          = "${var.application_name}-network-lb-logs"
  database_name = aws_athena_database.lb_access_logs[0].name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}" : "s3://${module.s3-bucket[0].bucket.id}/${var.application_name}/AWSLogs/${var.account_number}/elasticloadbalancing/${var.region}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name = "network_lb_logs"
      parameters = {
        "serialization.format" = "1",
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*):([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-0-9]*) ([-0-9]*) ([-0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)$"
      }
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
    }
    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "version"
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
      name = "listener_id"
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
      name = "tcp_connection_time"
      type = "double"
    }
    columns {
      name = "tls_handshake_time"
      type = "double"
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
      name = "incoming_tls_alert"
      type = "int"
    }
    columns {
      name = "cert_arn"
      type = "string"
    }
    columns {
      name = "certificate_serial"
      type = "string"
    }
    columns {
      name = "tls_cipher_suite"
      type = "string"
    }
    columns {
      name = "tls_protocol_version"
      type = "string"
    }
    columns {
      name = "tls_named_group"
      type = "string"
    }
    columns {
      name = "domain_name"
      type = "string"
    }
    columns {
      name = "alpn_fe_protocol"
      type = "string"
    }
    columns {
      name = "alpn_be_protocol"
      type = "string"
    }
    columns {
      name = "alpn_client_preference_list"
      type = "string"
    }
    columns {
      name = "tls_connection_creation_time"
      type = "string"
    }
  }
}