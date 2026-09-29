module "kms_hosted_pickup_pipeline" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.1"

  aliases                 = [local.pattern_name]
  description             = "KMS CMK for the push-to-s3-with-hosted-pickup SNS and SQS pipeline"
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

module "kms_hosted_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.1"

  for_each = local.hosted_pickup_entries

  aliases                 = ["s3/${local.hosted_bucket_names[each.key]}"]
  description             = "KMS CMK for hosted pickup dispatch entry ${each.key}"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  key_users          = [module.iam_role_mover[each.key].arn]

  key_statements = [
    {
      sid = "AllowCustomerPickupDecryption"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      resources = ["*"]
      principals = [{
        type        = "AWS"
        identifiers = [module.iam_role_customer_pickup[each.key].arn]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["s3.eu-west-2.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:s3:arn"
          values   = ["arn:aws:s3:::${local.hosted_bucket_names[each.key]}"]
        },
      ]
    },
  ]

  tags = local.tags
}