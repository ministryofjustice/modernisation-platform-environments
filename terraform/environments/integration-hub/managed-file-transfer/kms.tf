module "kms_cloudwatch_logs" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["transfer/logs/${local.component_name}"]
  description             = "KMS CMK for CloudWatch Logs encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudWatchLogsService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
        }
      ]
    },
    {
      sid = "AllowCloudWatchLogsAssociationCallers"
      actions = [
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/github-actions-apply",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/github-actions-plan",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}",
          ]
        }
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowPlatformUsersToReadEncryptedLogs"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
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
          values = [
            "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/AWSReservedSSO_*",
          ]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
    }
  ]
}

module "kms_sns" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["transfer/sns/${local.component_name}"]
  description             = "KMS CMK for SNS encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudWatchAlarmPublishers"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["cloudwatch.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowSNSService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]
    }
  ]
}

module "kms_s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/${each.key}"]
  description             = "Key for cryptographic functions on ${trimsuffix(each.value.bucket_prefix, "-")} S3 bucket"
  enable_default_policy   = true
  deletion_window_in_days = 30
  multi_region            = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

module "kms_secrets" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["transfer/secrets"]
  description             = "KMS CMK for Secrets Manager encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  # Explicitly allow only necessary roles to use the key
  key_users = [
    "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
  ]

  # Allow Secrets Manager to use the key
  key_statements = [
    {
      sid = "AllowSecretsManagerService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["secretsmanager.amazonaws.com"]
        }
      ]
    }
  ]
}
