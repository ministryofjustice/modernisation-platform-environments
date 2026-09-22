module "sns_hosted_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

  name                = local.pattern_name
  kms_master_key_id   = module.kms_hosted_pickup_pipeline.key_arn
  create_topic_policy = false

  tags = local.tags
}

data "aws_iam_policy_document" "sns_hosted_pickup" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [module.sns_hosted_pickup.topic_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge_hosted_pickup.eventbridge_rule_arns["push-to-s3-with-hosted-pickup"]]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "hosted_pickup" {
  arn    = module.sns_hosted_pickup.topic_arn
  policy = data.aws_iam_policy_document.sns_hosted_pickup.json
}

resource "aws_sns_topic_subscription" "hosted_pickup" {
  topic_arn            = module.sns_hosted_pickup.topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs_hosted_pickup.queue_arn
  raw_message_delivery = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_hosted_pickup_dlq.queue_arn
  })
}