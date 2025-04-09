module "transfer_server_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["logs/transfer-server"]
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
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/transfer-server-structured-logs"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "s3_transfer_landing_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/transfer/landing"]
  description           = "Family SFTP Server, Landing S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "supplier_data_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["secretsmanager/transfer/supplier-data"]
  description           = "Key for SFTP supplier data"
  enable_default_policy = true

  deletion_window_in_days = 7
}
