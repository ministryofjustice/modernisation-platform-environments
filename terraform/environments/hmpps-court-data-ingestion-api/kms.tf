module "secrets_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["${local.application_name}-secrets"]
  description             = "KMS key for ${local.application_name} secrets"
  enable_default_policy   = true
  deletion_window_in_days = 7
  tags                    = local.tags
}
