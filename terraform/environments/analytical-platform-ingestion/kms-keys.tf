module "transfer_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["logs/transfer"]
  description           = "CloudWatch Logs for the Transfer Server"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
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
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/transfer-structured-logs"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "s3_landing_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/landing"]
  description           = "Family SFTP Server, Landing S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_processed_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/processed"]
  description           = "Family SFTP Server, Processed S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_quarantine_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/quarantine"]
  description           = "Family SFTP Server, Quarantine S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_definitions_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/definitions"]
  description           = "Ingestion Scanning ClamAV S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_bold_egress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/bold-egress"]
  description           = "Used in the Bold Egress Solution"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformDataEngineeringProduction"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-bold-egress-${local.environment}"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}


module "quarantined_sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["sns/quarantined"]
  description           = "Key for quarantined notifications"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowS3"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "transferred_sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["sns/transferred"]
  description           = "Key for transferred notifications"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "govuk_notify_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["secretsmanager/govuk-notify"]
  description           = "Key for GOV.UK Notify data"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "supplier_data_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["secretsmanager/supplier-data"]
  description           = "Key for SFTP supplier data"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "slack_token_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["secretsmanager/slack-token"]
  description           = "Slack token for notifications"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "ec2_ebs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["ec2/ebs"]
  description           = "EC2 EBS KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "datasync_credentials_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["datasync/credentials"]
  description           = "DataSync Credentials KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_datasync_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/datasync"]
  description           = "DataSync S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "secretsmanager_common_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["secretsmanager/common"]
  description           = "Common secretsmanager KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
