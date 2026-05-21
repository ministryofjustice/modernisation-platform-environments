module "kms_s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases             = ["s3/${each.key}"]
  description         = "Key for cryptographic functions on ${trimsuffix(each.value.bucket_prefix, "-")} S3 bucket"
  multi_region        = false
  is_enabled          = true
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

module "kms_secrets" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1.0"

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
  key_users = concat(
    [
      "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
    ]
  )

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
    },
    {
      sid = "AllowCIRoles"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*"
      ]
      resources = ["*"]

      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
          ]
        }
      ]
    }
  ]
}