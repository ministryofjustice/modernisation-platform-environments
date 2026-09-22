module "sqs_hosted_pickup_dlq" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = "${local.pattern_name}-dlq"
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_hosted_pickup_pipeline.key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 300
  receive_wait_time_seconds  = 20

  tags = local.tags
}

module "sqs_hosted_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = local.pattern_name
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_hosted_pickup_pipeline.key_arn
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 1800
  receive_wait_time_seconds  = 20
  redrive_policy = {
    deadLetterTargetArn = module.sqs_hosted_pickup_dlq.queue_arn
    maxReceiveCount     = 5
  }

  tags = local.tags
}

data "aws_iam_policy_document" "sqs_hosted_pickup" {
  statement {
    sid     = "AllowSNSPublish"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [module.sqs_hosted_pickup.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.sns_hosted_pickup.topic_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "hosted_pickup" {
  queue_url = module.sqs_hosted_pickup.queue_url
  policy    = data.aws_iam_policy_document.sqs_hosted_pickup.json
}

data "aws_iam_policy_document" "sqs_hosted_pickup_dlq" {
  statement {
    sid     = "AllowEventBridgeAndSNS"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sns.amazonaws.com"]
    }

    resources = [module.sqs_hosted_pickup_dlq.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        module.eventbridge_hosted_pickup.eventbridge_rule_arns["push-to-s3-with-hosted-pickup"],
        module.sns_hosted_pickup.topic_arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "hosted_pickup_dlq" {
  queue_url = module.sqs_hosted_pickup_dlq.queue_url
  policy    = data.aws_iam_policy_document.sqs_hosted_pickup_dlq.json
}