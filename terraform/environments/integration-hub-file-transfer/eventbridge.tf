module "eventbridge_incoming_s3" {
  for_each = local.eventbridge_incoming_s3_rules

  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus                 = false
  create_role                = false
  create_log_delivery_source = false
  create_log_delivery        = false

  bus_name            = "default"
  append_rule_postfix = false

  rules = {
    (each.value.name) = {
      description   = each.value.description
      event_pattern = jsonencode(each.value.event_pattern)
    }
  }

  targets = {
    (each.value.name) = [
      {
        name = "${each.value.name}-to-sqs"
        arn  = module.sqs_incoming_s3_events.queue_arn
        input_transformer = {
          input_paths = {
            detail_type        = "$.detail-type"
            event_id           = "$.id"
            event_source       = "$.source"
            event_time         = "$.time"
            object_key         = "$.detail.object.key"
            object_size_bytes  = "$.detail.object.size"
            source_bucket_name = "$.detail.bucket.name"
            version_id         = "$.detail.object.version-id"
          }
          input_template = <<-EOF
              {
                "time": "<event_time>",
                "detail-type": "<detail_type>",
                "id": "<event_id>",
                "source": "<event_source>",
                "source_bucket_name": "<source_bucket_name>",
                "object_key": "<object_key>",
                "object_size_bytes": <object_size_bytes>,
                "version_id": "<version_id>"
              }
              EOF
        }
      }
    ]
  }

  tags = local.tags
}

module "eventbridge_guard_duty_malware_protection_for_s3" {
  for_each = local.eventbridge_guard_duty_malware_protection_for_s3_rules

  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus                 = false
  create_role                = false
  create_log_delivery_source = false
  create_log_delivery        = false

  bus_name            = "default"
  append_rule_postfix = false

  rules = {
    (each.value.name) = {
      description   = each.value.description
      event_pattern = jsonencode(each.value.event_pattern)
    }
  }

  targets = {
    (each.value.name) = [
      {
        name = "${each.value.name}-to-sqs"
        arn  = module.sqs_guard_duty_malware_protection_for_s3_events.queue_arn
        input_transformer = {
          input_paths = {
            detail_type        = "$.detail-type"
            event_id           = "$.id"
            event_source       = "$.source"
            event_time         = "$.time"
            object_key         = "$.detail.s3ObjectDetails.objectKey"
            scan_result_status = "$.detail.scanResultDetails.scanResultStatus"
            source_bucket_name = "$.detail.s3ObjectDetails.bucketName"
            version_id         = "$.detail.s3ObjectDetails.versionId"
          }
          input_template = <<-EOF
            {
              "time": "<event_time>",
              "detail-type": "<detail_type>",
              "id": "<event_id>",
              "source": "<event_source>",
              "source_bucket_name": "<source_bucket_name>",
              "destination_bucket_key": "${each.value.destination_bucket_key}",
              "delete_source": ${jsonencode(each.value.delete_source)},
              "object_key": "<object_key>",
              "version_id": "<version_id>",
              "scan_result_status": "<scan_result_status>"
            }
            EOF
        }
      }
    ]
  }

  tags = local.tags
}