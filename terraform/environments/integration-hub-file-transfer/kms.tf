module "kms_cloudwatch_logs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["logs/${local.application_name}-${local.environment}"]
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
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
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

  tags = local.tags
}

module "kms_dynamodb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["dynamodb/idempotency"]
  description             = "Key for cryptographic functions on DynamoDB tables"
  enable_default_policy   = true
  deletion_window_in_days = 30
  multi_region            = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowDynamoDBUseOfTheKey"
      actions = [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
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
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "StringLike"
          variable = "kms:ViaService"
          values   = ["dynamodb.*.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowDynamoDBServiceToDescribeTheKey"
      actions = [
        "kms:Describe*",
        "kms:Get*",
        "kms:List*",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["dynamodb.amazonaws.com"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "kms_s3_audit" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/audit"]
  description             = "Key for cryptographic functions on ${local.application_name}-${local.environment}-cloudtrail-logs S3 bucket"
  enable_default_policy   = true
  deletion_window_in_days = 30
  multi_region            = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudTrailToEncryptLogs"
      actions = [
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = ["arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.application_name}-${local.environment}-s3-data-events"]
        },
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "kms_s3_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/${each.key}"]
  description             = "Key for cryptographic functions on ${each.value.bucket} S3 bucket"
  enable_default_policy   = true
  deletion_window_in_days = 30
  multi_region            = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  tags = local.tags
}

module "kms_sqs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["sqs/${local.application_name}-${local.environment}"]
  description             = "KMS CMK for SQS encryption"
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
      sid = "AllowEventBridgePublishers"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
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
      sid = "AllowSQSService"
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
          identifiers = ["sqs.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:sqs:queueArn"
          values   = ["arn:aws:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
        }
      ]
    }
  ]

  tags = local.tags
}