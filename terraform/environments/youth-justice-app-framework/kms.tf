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
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*",
          ]
        }
      ]
    }
  ]

  tags = local.tags
}
#todo add to all secrets
