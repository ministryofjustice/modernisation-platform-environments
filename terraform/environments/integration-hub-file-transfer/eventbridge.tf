module "eventbridge_default_bus" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  bus_name                   = "default"
  create_bus                 = false
  create_log_delivery        = false
  create_log_delivery_source = false
  append_rule_postfix        = false
  create_role                = false

  rules = {
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
  }

  targets = {
    "incoming-s3-object-created" = [
      {
        name            = "file-received-v1"
        dead_letter_arn = module.sqs_eventbridge_default_dlq.queue_arn
        arn             = module.lambda_file_received_adapter.lambda_function_arn
      }
    ]
  }

  tags = local.tags
}

module "eventbridge_file_transfer_bus" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  bus_name        = local.application_name
  create_archives = true

  archives = {
    "${local.application_name}-archive" = {
      description    = "Archive of all file transfer events"
      retention_days = local.eventbridge_retention_days
    }
  }

  log_config = {
    include_detail = "FULL"
    level          = "INFO"
  }

  log_delivery = {
    cloudwatch_logs = {
      destination_arn = module.cloudwatch_eventbridge.cloudwatch_log_group_arn
    }
  }

  tags = local.tags
}