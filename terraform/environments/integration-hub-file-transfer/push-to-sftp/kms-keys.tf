module "kms_push_to_sftp" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  aliases                 = [local.pattern_name]
  description             = "KMS CMK for the push-to-sftp SNS and SQS pipeline"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    # EventBridge-to-encrypted-SNS publishing does not support SourceAccount/SourceArn conditions.
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

module "kms_credentials" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  aliases                 = ["${local.pattern_name}-credentials"]
  description             = "KMS CMK for independently administered SFTP keypair secrets"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  key_administrators      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid       = "AllowModernisationPlatformDeveloperDecryptPublicKey"
      actions   = ["kms:Decrypt"]
      resources = ["*"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values   = [local.modernisation_platform_developer_role_arn_pattern]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
        },
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:SecretARN"
          values   = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.sftp_key_secret_prefix}/*/public-??????"]
        },
      ]
    },
  ]

  tags = local.tags
}