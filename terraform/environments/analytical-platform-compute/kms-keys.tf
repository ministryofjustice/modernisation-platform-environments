module "mojap_compute_logs_s3_kms_eu_west_2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-compute-logs-eu-west-2"]
  description           = "mojap-compute-logs eu-west-2 S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags

  key_statements = [
    {
      sid    = "AllowS3Logging"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logging.s3.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logging.s3.amazonaws.com"]
        }
      ]
    }
  ]
}

module "mojap_compute_logs_s3_kms_eu_west_1" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  providers = {
    aws = aws.analytical-platform-compute-eu-west-1
  }

  aliases               = ["s3/mojap-compute-logs-eu-west-1"]
  description           = "mojap-compute-logs eu-west-1 S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags

  key_statements = [
    {
      sid    = "AllowS3Logging"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logging.s3.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logging.s3.amazonaws.com"]
        }
      ]
    }
  ]
}
