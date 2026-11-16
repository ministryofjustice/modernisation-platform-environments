module "sqs_notifications_dlq" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = "${local.pattern_name}-dlq"
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_notifications_pipeline.key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 360
  receive_wait_time_seconds  = 20

  tags = local.tags
}

module "sqs_notifications_eventbridge_dlq" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = "${local.pattern_name}-eventbridge-dlq"
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_notifications_pipeline.key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 360
  receive_wait_time_seconds  = 20

  tags = local.tags
}

module "sqs_notifications_sns_dlq" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = "${local.pattern_name}-sns-dlq"
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_notifications_pipeline.key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 360
  receive_wait_time_seconds  = 20

  tags = local.tags
}

module "sqs_notifications" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = local.pattern_name
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = false
  kms_master_key_id          = module.kms_notifications_pipeline.key_arn
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 5400
  receive_wait_time_seconds  = 20
  redrive_policy = {
    deadLetterTargetArn = module.sqs_notifications_dlq.queue_arn
    maxReceiveCount     = 5
  }

  tags = local.tags
}

data "aws_iam_policy_document" "sqs_notifications" {
  statement {
    sid     = "AllowSNSPublish"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [module.sqs_notifications.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.sns_notifications.topic_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications" {
  queue_url = module.sqs_notifications.queue_url
  policy    = data.aws_iam_policy_document.sqs_notifications.json
}

data "aws_iam_policy_document" "sqs_notifications_dlq" {
  statement {
    sid     = "AllowEventBridgeFailedDeliveries"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [module.sqs_notifications_eventbridge_dlq.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge_notifications.eventbridge_rule_arns["pull-from-presigned-url"]]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications_dlq" {
  queue_url = module.sqs_notifications_eventbridge_dlq.queue_url
  policy    = data.aws_iam_policy_document.sqs_notifications_dlq.json
}

data "aws_iam_policy_document" "sqs_notifications_sns_dlq" {
  statement {
    sid       = "AllowSNSFailedDeliveries"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [module.sqs_notifications_sns_dlq.queue_arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.sns_notifications.topic_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications_sns_dlq" {
  queue_url = module.sqs_notifications_sns_dlq.queue_url
  policy    = data.aws_iam_policy_document.sqs_notifications_sns_dlq.json
}

resource "aws_sqs_queue_redrive_allow_policy" "notifications_processing" {
  queue_url = module.sqs_notifications_dlq.queue_url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [module.sqs_notifications.queue_arn]
  })
}