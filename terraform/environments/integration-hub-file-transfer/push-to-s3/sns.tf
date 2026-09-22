module "sns_push_to_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

  name                = local.pattern_name
  kms_master_key_id   = module.kms_push_to_s3.key_arn
  create_topic_policy = false

  tags = local.tags
}

data "aws_iam_policy_document" "sns_push_to_s3" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [module.sns_push_to_s3.topic_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge_push_to_s3.eventbridge_rule_arns["push-to-s3"]]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "push_to_s3" {
  arn    = module.sns_push_to_s3.topic_arn
  policy = data.aws_iam_policy_document.sns_push_to_s3.json
}

resource "aws_sns_topic_subscription" "push_to_s3" {
  topic_arn            = module.sns_push_to_s3.topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs_push_to_s3.queue_arn
  raw_message_delivery = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_push_to_s3_dlq.queue_arn
  })
}