module "kms_s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  description           = "Key for cryptographic functions on ${trimsuffix(each.value.bucket_prefix, "-")} S3 bucket"
  deletion_window_in_days = 30
  enable_default_policy = true
  enable_key_rotation   = true
  key_usage             = "ENCRYPT_DECRYPT"
  is_enabled            = true
  aliases               = ["integration-hub/s3/${trimsuffix(each.value.bucket_prefix, "-")}"]

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

module "kms_secrets" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1.0"

  description             = "KMS CMK for Secrets Manager encryption"
  deletion_window_in_days = 30
  enable_default_policy   = true
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  aliases                 = ["integration-hub/secrets"]

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  # Explicitly allow only necessary roles to use the key
  key_users = [
    for role_name in toset([
      var.collaborator_access,
      "MemberInfrastructureAccess",
    ]) :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
  ]

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
            for role_name in toset([
              var.collaborator_access,
              "MemberInfrastructureAccess",
            ]) :
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
          ]
        }
      ]
    }
  ]
}