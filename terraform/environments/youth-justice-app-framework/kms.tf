module "kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  deletion_window_in_days = 7
  description             = "KMS key for ${local.project_name}"
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = [local.project_name]

  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          ]
        }
      ]
    },
    {
      sid = "AllowLambdaFunctionAccess"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/update-dc-names-lambda-role"]
        }
      ]
    },
    {
      sid    = "AllowInspectorUseOfKMSKey",
      effect = "Allow",
      principals = [
        {
          type        = "Service"
          identifiers = ["inspector2.amazonaws.com"]
        }
      ],
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      resources = ["*"]
    },
    {
      sid = "AllowSESPublishToSNSEncryptedTopics"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt",
        "kms:Encrypt"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["ses.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "StringEquals"
          variable = "AWS:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]
  tags = local.tags
}
#todo add to all secrets

## KMS for CloudFront WAF logs
module "kms_us_east_1" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"
  providers = { aws = aws.us-east-1 }

  description         = "KMS key for CloudFront WAF logs"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  aliases = ["${local.project_name}-cf-logs"]

  tags = local.tags
}