# Athena over the shared load balancer access logs bucket.
#
# There is one table per load balancer type, partitioned by:
#   lb  - the load balancer's directory in the bucket (e.g. 'ccms-pui-feasibility')
#   day - the log date, 'yyyy/MM/dd'
# Partition projection is used, so no crawler or MSCK REPAIR is needed. Filter on both partitions to keep scans small:
#   SELECT * FROM alb_access_logs WHERE lb = 'ccms-pui-feasibility' AND day = '2026/09/29' LIMIT 100;

resource "aws_glue_catalog_database" "lb_access_logs" {
  name        = replace("${local.application_name}_lb_access_logs", "-", "_")
  description = "Access logs for the ccms-feasibility load balancers"
}

resource "aws_athena_workgroup" "lb_access_logs" {
  name          = "${local.application_name}-lb-access-logs"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3_lb_access_logs.bucket.id}/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-lb-access-logs"
  })
}

# ALB access log format: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
resource "aws_glue_catalog_table" "alb_access_logs" {
  name          = "alb_access_logs"
  database_name = aws_glue_catalog_database.lb_access_logs.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"                     = "TRUE"
    "projection.enabled"           = "true"
    "projection.lb.type"           = "enum"
    "projection.lb.values"         = join(",", local.alb_access_log_prefixes)
    "projection.day.type"          = "date"
    "projection.day.range"         = "2026/01/01,NOW"
    "projection.day.format"        = "yyyy/MM/dd"
    "projection.day.interval"      = "1"
    "projection.day.interval.unit" = "DAYS"
    "storage.location.template"    = local.lb_access_logs_location_template
  }

  partition_keys {
    name = "lb"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${module.s3_lb_access_logs.bucket.id}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      parameters = {
        "serialization.format" = "1"
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^ ]*)\" \"([^ ]*)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)?( .*)?"
      }
    }

    dynamic "columns" {
      for_each = [
        ["type", "string"],
        ["time", "string"],
        ["elb", "string"],
        ["client_ip", "string"],
        ["client_port", "int"],
        ["target_ip", "string"],
        ["target_port", "int"],
        ["request_processing_time", "double"],
        ["target_processing_time", "double"],
        ["response_processing_time", "double"],
        ["elb_status_code", "int"],
        ["target_status_code", "string"],
        ["received_bytes", "bigint"],
        ["sent_bytes", "bigint"],
        ["request_verb", "string"],
        ["request_url", "string"],
        ["request_proto", "string"],
        ["user_agent", "string"],
        ["ssl_cipher", "string"],
        ["ssl_protocol", "string"],
        ["target_group_arn", "string"],
        ["trace_id", "string"],
        ["domain_name", "string"],
        ["chosen_cert_arn", "string"],
        ["matched_rule_priority", "string"],
        ["request_creation_time", "string"],
        ["actions_executed", "string"],
        ["redirect_url", "string"],
        ["lambda_error_reason", "string"],
        ["target_port_list", "string"],
        ["target_status_code_list", "string"],
        ["classification", "string"],
        ["classification_reason", "string"],
        ["conn_trace_id", "string"],
        ["extra_fields", "string"], # absorbs any fields AWS appends to the format in future
      ]
      content {
        name = columns.value[0]
        type = columns.value[1]
      }
    }
  }
}

# NLB TLS access log format: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html
resource "aws_glue_catalog_table" "nlb_access_logs" {
  name          = "nlb_access_logs"
  database_name = aws_glue_catalog_database.lb_access_logs.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"                     = "TRUE"
    "projection.enabled"           = "true"
    "projection.lb.type"           = "enum"
    "projection.lb.values"         = join(",", local.nlb_access_log_prefixes)
    "projection.day.type"          = "date"
    "projection.day.range"         = "2026/01/01,NOW"
    "projection.day.format"        = "yyyy/MM/dd"
    "projection.day.interval"      = "1"
    "projection.day.interval.unit" = "DAYS"
    "storage.location.template"    = local.lb_access_logs_location_template
  }

  partition_keys {
    name = "lb"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${module.s3_lb_access_logs.bucket.id}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      parameters = {
        "serialization.format" = "1"
        "input.regex"          = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*):([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-0-9]*) ([-0-9]*) ([-0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)$"
      }
    }

    dynamic "columns" {
      for_each = [
        ["type", "string"],
        ["version", "string"],
        ["time", "string"],
        ["elb", "string"],
        ["listener_id", "string"],
        ["client_ip", "string"],
        ["client_port", "int"],
        ["target_ip", "string"],
        ["target_port", "int"],
        ["tcp_connection_time_ms", "double"],
        ["tls_handshake_time_ms", "double"],
        ["received_bytes", "bigint"],
        ["sent_bytes", "bigint"],
        ["incoming_tls_alert", "int"],
        ["cert_arn", "string"],
        ["certificate_serial", "string"],
        ["tls_cipher_suite", "string"],
        ["tls_protocol_version", "string"],
        ["tls_named_group", "string"],
        ["domain_name", "string"],
        ["alpn_fe_protocol", "string"],
        ["alpn_be_protocol", "string"],
        ["alpn_client_preference_list", "string"],
        ["tls_connection_creation_time", "string"],
      ]
      content {
        name = columns.value[0]
        type = columns.value[1]
      }
    }
  }
}

# Saved queries, available from the workgroup's "Saved queries" tab in the Athena console

resource "aws_athena_named_query" "alb_errors_last_day" {
  name        = "alb-5xx-4xx-errors-last-24h"
  description = "ALB requests returning 4xx/5xx in the last 24 hours, per load balancer and path"
  workgroup   = aws_athena_workgroup.lb_access_logs.id
  database    = aws_glue_catalog_database.lb_access_logs.name
  query       = <<-EOT
    SELECT lb, elb_status_code, target_status_code, request_verb, url_extract_path(request_url) AS path, count(*) AS requests
    FROM alb_access_logs
    WHERE day >= date_format(current_date - interval '1' day, '%Y/%m/%d')
      AND elb_status_code >= 400
    GROUP BY 1, 2, 3, 4, 5
    ORDER BY requests DESC
    LIMIT 100;
  EOT
}

resource "aws_athena_named_query" "alb_slowest_requests_last_day" {
  name        = "alb-slowest-requests-last-24h"
  description = "Slowest ALB requests (by target processing time) in the last 24 hours"
  workgroup   = aws_athena_workgroup.lb_access_logs.id
  database    = aws_glue_catalog_database.lb_access_logs.name
  query       = <<-EOT
    SELECT lb, time, client_ip, request_verb, request_url, elb_status_code, target_processing_time
    FROM alb_access_logs
    WHERE day >= date_format(current_date - interval '1' day, '%Y/%m/%d')
    ORDER BY target_processing_time DESC
    LIMIT 100;
  EOT
}

resource "aws_athena_named_query" "alb_requests_by_client_last_day" {
  name        = "alb-requests-by-client-ip-last-24h"
  description = "ALB request counts per load balancer and client IP in the last 24 hours"
  workgroup   = aws_athena_workgroup.lb_access_logs.id
  database    = aws_glue_catalog_database.lb_access_logs.name
  query       = <<-EOT
    SELECT lb, client_ip, count(*) AS requests
    FROM alb_access_logs
    WHERE day >= date_format(current_date - interval '1' day, '%Y/%m/%d')
    GROUP BY 1, 2
    ORDER BY requests DESC
    LIMIT 100;
  EOT
}

resource "aws_athena_named_query" "nlb_connections_last_day" {
  name        = "nlb-tls-connections-last-24h"
  description = "NLB TLS connection counts and handshake times per load balancer and client IP in the last 24 hours"
  workgroup   = aws_athena_workgroup.lb_access_logs.id
  database    = aws_glue_catalog_database.lb_access_logs.name
  query       = <<-EOT
    SELECT lb, client_ip, tls_protocol_version, count(*) AS connections, avg(tls_handshake_time_ms) AS avg_handshake_ms
    FROM nlb_access_logs
    WHERE day >= date_format(current_date - interval '1' day, '%Y/%m/%d')
    GROUP BY 1, 2, 3
    ORDER BY connections DESC
    LIMIT 100;
  EOT
}
