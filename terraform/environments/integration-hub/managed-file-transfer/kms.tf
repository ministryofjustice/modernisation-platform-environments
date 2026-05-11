module "kms_s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  description         = "Key for cryptographic functions on ${trimsuffix(each.value.bucket_prefix, "-")} S3 bucket"
  multi_region        = false
  is_enabled          = true
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true

  # Allow the root account as administrator
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}