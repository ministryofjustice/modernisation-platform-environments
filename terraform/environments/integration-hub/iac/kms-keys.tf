module "pagerduty_state_kms" {
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/${local.pagerduty_state_bucket_name}"]
  description             = "KMS key for Integration Hub PagerDuty Terraform state"
  enable_default_policy   = false
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  key_administrators      = ["arn:aws:iam::${local.account_id}:root"]

  key_statements = [
    {
      sid       = "AllowPagerDutyStateBucketUse"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
      resources = ["*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]

      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values   = local.pagerduty_state_allowed_principal_arns
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["s3.eu-west-2.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:s3:arn"
          values   = ["arn:aws:s3:::${local.pagerduty_state_bucket_name}"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "pagerduty_api_key_kms" {
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["secrets/${local.pagerduty_secret_name}"]
  description             = "KMS key for the Integration Hub PagerDuty API token"
  enable_default_policy   = false
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  key_administrators      = ["arn:aws:iam::${local.account_id}:root"]

  key_statements = [
    {
      sid       = "AllowPagerDutyApiKeyUseThroughSecretsManager"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = ["*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]

      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values   = local.pagerduty_api_key_kms_principal_arns
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["secretsmanager.eu-west-2.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:SecretARN"
          values   = ["arn:aws:secretsmanager:eu-west-2:${local.account_id}:secret:${local.pagerduty_secret_name}-*"]
        }
      ]
    }
  ]

  tags = local.tags
}
