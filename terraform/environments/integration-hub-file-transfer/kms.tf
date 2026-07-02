module "kms_s3_bucket" {
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/${each.key}"]
  description             = "Key for cryptographic functions on ${each.value.bucket} S3 bucket"
  enable_default_policy   = true
  deletion_window_in_days = 30
  multi_region            = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}
