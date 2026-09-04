module "destination_kms_key" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=af1d45558a6073c017a732d2273efcc733b34d0f" # v4.2.1

  aliases = [local.component_name]

  key_statements = [
    {
      sid = "AWSEventBridge"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    },
    {
      sid = "Firehose"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncrypt*",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["firehose.amazonaws.com"]
        }
      ]
    },
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.eu-west-2.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${local.component_name}"]
        }
      ]
    }
  ]
}

module "source_kms_key" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=af1d45558a6073c017a732d2273efcc733b34d0f" # v4.2.1

  providers = {
    aws = aws.us-east-1
  }

  aliases = ["${local.component_name}-source"]

  key_statements = [{
    sid = "AWSEventBridge"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
    principals = [{
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }]
  }]
}
