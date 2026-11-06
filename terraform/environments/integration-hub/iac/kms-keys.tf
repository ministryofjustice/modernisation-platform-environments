module "pagerduty_state_kms" {
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["s3/${local.pagerduty_state_bucket_name}"]
  description             = "KMS key for Integration Hub PagerDuty Terraform state"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  key_administrators      = ["arn:aws:iam::${local.account_id}:root"]

  tags = local.tags
}
