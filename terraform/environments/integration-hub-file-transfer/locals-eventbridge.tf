locals {
  eventbridge_schema_directory = "${path.module}/schemas"
  eventbridge_schemas          = fileset("${path.module}/schemas", "*.json")

  eventbridge_default_bus_rules = {
    "incoming-s3-object-created" = {
      description = "Transform incoming S3 Object Created notifications into FileReceived.v1 events"
      event_pattern = jsonencode({
        source        = ["aws.s3"]
        "detail-type" = ["Object Created"]
        detail = {
          bucket = {
            name = [module.s3_bucket["incoming"].s3_bucket_id]
          }
        }
      })
    }
    "guardduty-malware-scan-result" = {
      description = "Transform GuardDuty malware scan results into FileScanResultRecorded.v1 events"
      event_pattern = jsonencode({
        account       = [data.aws_caller_identity.current.account_id]
        source        = ["aws.guardduty"]
        "detail-type" = ["GuardDuty Malware Protection Object Scan Result"]
        resources     = [aws_guardduty_malware_protection_plan.this.arn]
        detail = {
          resourceType = ["S3_OBJECT"]
          s3ObjectDetails = {
            bucketName = [module.s3_bucket["processing"].s3_bucket_id]
          }
        }
      })
    }
  }

  eventbridge_default_bus_targets = {
    "incoming-s3-object-created" = [
      {
        name            = "file-received-v1"
        dead_letter_arn = module.sqs_eventbridge_default_dlq.queue_arn
        arn             = module.lambda_file_received_adapter.lambda_function_arn
      }
    ]
    "guardduty-malware-scan-result" = [
      {
        name            = "file-scan-result-recorded-v1"
        dead_letter_arn = module.sqs_eventbridge_default_dlq.queue_arn
        arn             = module.lambda_file_scan_result_recorded_adapter.lambda_function_arn
        retry_policy = {
          maximum_event_age_in_seconds = 21600
          maximum_retry_attempts       = 185
        }
      }
    ]
  }

  eventbridge_file_transfer_bus_rules = {
    "file-transfer-workflow" = {
      description = "Start the file transfer workflow for canonical FileReceived.v1 events"
      event_pattern = jsonencode({
        account       = [data.aws_caller_identity.current.account_id]
        source        = ["uk.gov.justice.service.managed-file-transfer"]
        "detail-type" = ["FileReceived.v1"]
        detail = {
          data = {
            object = {
              bucket = [module.s3_bucket["incoming"].s3_bucket_id]
            }
          }
        }
      })
    }
    "file-routing-workflow" = {
      description = "Start the file routing workflow for canonical FileScanResultRecorded.v1 events"
      event_pattern = jsonencode({
        account       = [data.aws_caller_identity.current.account_id]
        source        = ["uk.gov.justice.service.managed-file-transfer"]
        "detail-type" = ["FileScanResultRecorded.v1"]
        detail = {
          data = {
            object = {
              bucket = [module.s3_bucket["processing"].s3_bucket_id]
            }
          }
        }
      })
    }
  }

  eventbridge_file_transfer_bus_targets = {
    "file-transfer-workflow" = [
      {
        name            = "file-transfer-workflow"
        arn             = module.step_function_filereceived_workflow.state_machine_arn
        attach_role_arn = true
        dead_letter_arn = module.sqs_eventbridge_file_transfer_workflow_dlq.queue_arn
        retry_policy = {
          maximum_event_age_in_seconds = 86400
          maximum_retry_attempts       = 185
        }
      }
    ]
    "file-routing-workflow" = [
      {
        name            = "file-routing-workflow"
        arn             = module.step_function_filescanresultrecorded_workflow.state_machine_arn
        attach_role_arn = true
        dead_letter_arn = module.sqs_eventbridge_file_transfer_workflow_dlq.queue_arn
        retry_policy = {
          maximum_event_age_in_seconds = 86400
          maximum_retry_attempts       = 185
        }
      }
    ]
  }
}
