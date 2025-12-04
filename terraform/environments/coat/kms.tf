# COAT GitHub repositories KMS for Terraform state bucket
module "coat_github_repos_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/coat-github-repos"]
  description           = "S3 COAT github repos terraform KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "cur_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["s3/cur"]
  description             = "S3 CUR KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7

  key_statements = [
    {
      sid = "AllowReplicationRole"
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
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-cur-reports-v2-hourly-replication-role",
            "arn:aws:iam::${local.coat_prod_account_id}:role/moj-coat-${local.prod_environment}-cur-reports-cross-role"
          ]
        }
      ]
    },
    {
      sid = "AllowGlueService"
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
          identifiers = ["glue.amazonaws.com"]
        }
      ]
    }
  ]

  tags = local.tags
}