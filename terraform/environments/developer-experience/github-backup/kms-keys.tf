module "github_backup_key" {
  count = local.is_production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=af1d45558a6073c017a732d2273efcc733b34d0f" # v4.2.1

  aliases                 = ["github-backup"]
  description             = "Encrypt GitHub repository backup archives"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}
