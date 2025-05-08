module "mwaa_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["mwaa/default"]
  enable_default_policy = true
  key_statements = [
    {
      # https://docs.aws.amazon.com/mwaa/latest/userguide/custom-keys-certs.html#custom-keys-certs-grant-policies-attach
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
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
          values   = ["arn:aws:logs:${data.aws_region.current.name}:*:*"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7

  tags = local.tags
}
