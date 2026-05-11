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
            object_key         = "$.detail.s3ObjectDetails.objectKey"
            version_id         = "$.detail.s3ObjectDetails.versionId"
            scan_result_status = "$.detail.scanResultDetails.scanResultStatus"
          }
          input_template = <<-EOF
					{
					  "source_bucket": "${module.s3_bucket["processing"].s3_bucket_id}",
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