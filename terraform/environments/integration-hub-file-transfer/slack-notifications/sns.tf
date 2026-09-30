module "sns_notifications" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

  name                = local.pattern_name
  kms_master_key_id   = module.kms_notifications_pipeline.key_arn
  create_topic_policy = false

  tags = local.tags
}

data "aws_iam_policy_document" "sns_notifications" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [module.sns_notifications.topic_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge_notifications.eventbridge_rule_arns["slack-notifications"]]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "notifications" {
  arn    = module.sns_notifications.topic_arn
  policy = data.aws_iam_policy_document.sns_notifications.json
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn            = module.sns_notifications.topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs_notifications.queue_arn
  raw_message_delivery = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_notifications_sns_dlq.queue_arn
  })
}