module "kms_push_to_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.1"

  aliases                 = [local.pattern_name]
  description             = "KMS CMK for the push-to-s3 SNS and SQS pipeline"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowEventBridgePublishers"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    },
    {
      sid = "AllowSNSPublishers"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    },
    {
      sid = "AllowSQSService"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["sqs.amazonaws.com"]
      }]
      condition = [{
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:sqs:queueArn"
        values   = ["arn:aws:sqs:eu-west-2:${data.aws_caller_identity.current.account_id}:${local.pattern_name}*"]
      }]
    },
  ]

  tags = local.tags
}