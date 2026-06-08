module "ai_gateway_cloudwatch_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  description           = "KMS key for AI Gateway CloudWatch Logs encryption"
  enable_default_policy = true

  aliases = ["cloudwatch/${local.component_name}"]

  key_statements = [
    {
      sid = "AllowCloudWatchLogsEncryption"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey",
      ]
      resources = ["*"]
      effect    = "Allow"
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
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-${local.component_name}"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "ai_gateway_elasticache_logs_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  description           = "KMS key for AI Gateway ElastiCache CloudWatch Logs encryption"
  enable_default_policy = true

  aliases = ["cloudwatch/${local.component_name}-elasticache"]

  key_statements = [
    {
      sid = "AllowCloudWatchLogsEncryption"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey",
      ]
      resources = ["*"]
      effect    = "Allow"
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
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticache/${local.component_name}/*"
          ]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "ai_gateway_audit_logs_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  description           = "KMS key for AI Gateway audit logs S3 bucket encryption"
  enable_default_policy = true

  aliases = ["s3/${local.component_name}-audit-logs"]

  deletion_window_in_days = 7
}

module "ai_gateway_aurora_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  description           = "KMS key for AI Gateway Aurora PostgreSQL encryption"
  enable_default_policy = true

  aliases = ["aurora/${local.component_name}"]

  key_statements = [
    {
      sid = "AllowRDSServiceEncryption"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["rds.amazonaws.com"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7

}
