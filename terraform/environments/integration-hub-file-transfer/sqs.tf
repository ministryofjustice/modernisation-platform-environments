module "sqs_incoming_s3_events" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-incoming-s3-notifications"
  use_name_prefix = false

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
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            for rule_key, rule in local.eventbridge_incoming_s3_rules : module.eventbridge_incoming_s3[rule_key].eventbridge_rule_arns[rule.name]
          ]
        }
      ]
    }
    secure_transport = {
      sid     = "DenyUnsecureTransport"
      effect  = "Deny"
      actions = ["sqs:*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]

      condition = [
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["false"]
        }
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.application_name}-incoming-s3-notifications-dlq"

  kms_master_key_id             = module.kms_sqs.key_arn
  message_retention_seconds     = 259200
  visibility_timeout_seconds    = 720
  receive_wait_time_seconds     = 20
  dlq_message_retention_seconds = 1209600

  redrive_policy = {
    maxReceiveCount = 5
  }

  tags = local.tags
}

module "sqs_guard_duty_malware_protection_for_s3_events" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-guard-duty-malware-protection-for-s3-events"
  use_name_prefix = false

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
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            for rule_key, rule in local.eventbridge_guard_duty_malware_protection_for_s3_rules : module.eventbridge_guard_duty_malware_protection_for_s3[rule_key].eventbridge_rule_arns[rule.name]
          ]
        }
      ]
    }
    secure_transport = {
      sid     = "DenyUnsecureTransport"
      effect  = "Deny"
      actions = ["sqs:*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]

      condition = [
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["false"]
        }
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.application_name}-guard-duty-malware-protection-for-s3-events-dlq"

  kms_master_key_id             = module.kms_sqs.key_arn
  message_retention_seconds     = 259200
  visibility_timeout_seconds    = 720
  receive_wait_time_seconds     = 20
  dlq_message_retention_seconds = 1209600

  redrive_policy = {
    maxReceiveCount = 5
  }

  tags = local.tags
}
