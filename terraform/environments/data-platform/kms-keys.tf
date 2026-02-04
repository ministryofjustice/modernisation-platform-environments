module "s3_access_logs_kms_key" {

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=926e8c8aac77189686262b6f95e8e6bedcc9acfa" # v4.1.1

  aliases               = ["s3/mojdp-${local.environment}-s3-access-logs"]
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowS3ServerAccessLogging"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logging.s3.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
