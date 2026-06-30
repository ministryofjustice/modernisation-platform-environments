module "sqs_unscanned_s3_notifications" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name            = "${local.application_name}-unscanned-s3-notifications"
  use_name_prefix = false

  create_queue_policy = true
  queue_policy_statements = {
    s3 = {
      sid     = "AllowUnscannedBucketSendMessage"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.s3_bucket["unscanned"].s3_bucket_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.application_name}-unscanned-s3-notifications-dlq"

  message_retention_seconds     = 1209600
  visibility_timeout_seconds    = 180
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
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            for rule_key, rule in local.eventbridge_guard_duty_malware_protection_for_s3_rules : module.eventbridge_guard_duty_malware_protection_for_s3[rule_key].eventbridge_rule_arns[rule.name]
          ]
        }
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.application_name}-guard-duty-malware-protection-for-s3-events-dlq"

  message_retention_seconds     = 1209600
  visibility_timeout_seconds    = 180
  receive_wait_time_seconds     = 20
  dlq_message_retention_seconds = 1209600

  redrive_policy = {
    maxReceiveCount = 5
  }

  tags = local.tags
}
