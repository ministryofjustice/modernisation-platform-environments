module "rds_encryption" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  description           = "KMS key for app RDS PostgreSQL encryption"
  enable_default_policy = true

  aliases = ["rds/${local.component_name}"]

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
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["rds.${data.aws_region.current.region}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = ["arn:aws:rds:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:db:${local.component_name}"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "app_secret_encryption" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["secrets/${local.component_name}"]
  description           = "App Secrets Manager KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
