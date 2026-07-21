module "sqs_eventbridge_default_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-eventbridge-default-dlq"
  use_name_prefix = false

  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 20

  create_dlq          = false
  create_queue_policy = true
  queue_policy_statements = {
    eventbridge = {
      sid     = "AllowEventBridgeSendMessage"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            module.eventbridge_default_bus.eventbridge_rule_arns["incoming-s3-object-created"],
          ]
        }
      ]
    }
  }

  tags = local.tags
}

module "sqs_lambda_file_received_adapter_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-lambda-file-received-adapter-dlq"
  use_name_prefix = false

  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 20

  create_dlq = false

  tags = local.tags
}

module "sqs_lambda_file_scan_result_recorded_adapter_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-lambda-file-scan-result-recorded-adapter-dlq"
  use_name_prefix = false

  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 20

  create_dlq = false

  tags = local.tags
}

module "sqs_eventbridge_file_transfer_workflow_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-file-transfer-workflow-dlq"
  use_name_prefix = false

  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 20

  create_dlq          = false
  create_queue_policy = true
  queue_policy_statements = {
    eventbridge = {
      sid     = "AllowEventBridgeSendMessage"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            module.eventbridge_file_transfer_bus.eventbridge_rule_arns["file-transfer-workflow"],
            module.eventbridge_file_transfer_bus.eventbridge_rule_arns["file-routing-workflow"],
          ]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }

  tags = local.tags
}