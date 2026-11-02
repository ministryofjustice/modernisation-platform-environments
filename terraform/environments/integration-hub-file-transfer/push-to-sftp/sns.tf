module "sns_push_to_sftp" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.2.0"

  name                = local.pattern_name
  kms_master_key_id   = module.kms_push_to_sftp.key_arn
  create_topic_policy = false

  tags = local.tags
}

data "aws_iam_policy_document" "sns_push_to_sftp" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [module.sns_push_to_sftp.topic_arn]
  }
}

resource "aws_sns_topic_policy" "push_to_sftp" {
  arn    = module.sns_push_to_sftp.topic_arn
  policy = data.aws_iam_policy_document.sns_push_to_sftp.json
}

resource "aws_sns_topic_subscription" "push_to_sftp" {
  topic_arn            = module.sns_push_to_sftp.topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs_push_to_sftp.queue_arn
  raw_message_delivery = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_push_to_sftp_dlq["sns"].queue_arn
  })
}