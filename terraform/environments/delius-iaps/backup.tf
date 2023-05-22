// create an aws backup vault to store rds backups in and share it with the pre production aws account
data "aws_kms_key" "general_hmpps" {
  key_id = "general-hmpps"
}

resource "aws_backup_vault" "data_refresher" {
  name        = "iaps-data-refresher"
  kms_key_arn = data.aws_kms_key.general_hmpps.arn
  tags        = var.tags
}

resource "aws_backup_plan" "database" {
  name = "daily-rds-backups"

  rule {
    rule_name         = "daily-rds-backups"
    target_vault_name = aws_backup_vault.data_refresher.name

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
  name               = "AWSBackup"
  assume_role_policy = data.aws_iam_policy_document.backup-assume-role-policy.json
}

data "aws_iam_policy_document" "backup-assume-role-policy" {
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
  role       = aws_iam_role.backup.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}


resource "aws_backup_selection" "production" {
  name         = "is-production-database"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.database.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Name"
    value = aws_db_instance.iaps.name
  }
}

data "aws_ssm_parameter" "account_numbers_vault_share" {
  name = "/Backup/ShareVaultAccountNumbers"
}

data "aws_iam_policy_document" "share_vault_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_ssm_parameter.account_numbers_vault_share.value}:root"]
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = ["*"]
  }
}
resource "aws_backup_vault_policy" "share_with_preprod" {
  backup_vault_name = aws_backup_vault.data_refresher.name
  policy            = data.aws_iam_policy_document.share_vault_policy.json
}
