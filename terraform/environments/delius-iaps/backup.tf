// create an aws backup vault to store rds backups in and share it with the pre production aws account
data "aws_kms_key" "general_hmpps" {
  count  = local.is-production ? 1 : 0
  key_id = "general-hmpps"
}

resource "aws_backup_vault" "data_refresher" {
  count       = local.is-production ? 1 : 0
  name        = "iaps-data-refresher"
  kms_key_arn = data.aws_kms_key.general_hmpps[0].arn
  tags        = var.tags
}

resource "aws_backup_plan" "database" {
  count = local.is-production ? 1 : 0
  name  = "daily-rds-backups"

  rule {
    rule_name         = "daily-rds-backups"
    target_vault_name = aws_backup_vault.data_refresher[0].name

    # Backup every day at 00:30am
    schedule = "cron(30 0 * * ? *)"

    # The amount of time in minutes to start and finish a backup
    ## Start the backup within 1 hour of the schedule
    start_window = (1 * 60)
    ## Complete the backup within 6 hours of starting
    completion_window = (6 * 60)
  }
  tags = var.tags
}

resource "aws_iam_role" "backup" {
  count              = local.is-production ? 1 : 0
  name               = "AWSBackup"
  assume_role_policy = data.aws_iam_policy_document.backup-assume-role-policy[0].json
}

data "aws_iam_policy_document" "backup-assume-role-policy" {
  count   = local.is-production ? 1 : 0
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = local.is-production ? 1 : 0
  role       = aws_iam_role.backup[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}


resource "aws_backup_selection" "production" {
  count        = local.is-production ? 1 : 0
  name         = "is-production-database"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.database[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Name"
    value = aws_db_instance.iaps.name
  }
}

data "aws_ssm_parameter" "account_numbers_vault_share" {
  count = local.is-production ? 1 : 0
  name  = "/Backup/ShareVaultAccountNumbers"
}

data "aws_iam_policy_document" "share_vault_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_ssm_parameter.account_numbers_vault_share[0].value}:root"]
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = ["*"]
  }
}
resource "aws_backup_vault_policy" "share_with_preprod" {
  backup_vault_name = aws_backup_vault.data_refresher[0].name
  policy            = data.aws_iam_policy_document.share_vault_policy[0].json
}
