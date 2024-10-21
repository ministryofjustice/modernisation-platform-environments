resource "aws_backup_vault" "cwa" {
  name = "${local.application_name_short}-backup-vault"
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-backup-vault" },
  )
}
resource "aws_backup_plan" "cwa" {

  name = "${local.application_name_short}-backup-daily-retain-35-days"

  rule {
    rule_name         = "${local.application_name_short}-backup-daily-retain-35-days"
    target_vault_name = aws_backup_vault.cwa.name

    # Backup every day at 12:00am
    schedule = "cron(0 0 * * ? *)"

    # The amount of time in minutes to start and finish a backup
    ## Start the backup within 1 hour of the schedule
    start_window = (1 * 60)
    ## Complete the backup within 6 hours of starting
    completion_window = (6 * 60)

    lifecycle {
      delete_after = 35
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-backup-plan" },
  )
}

resource "aws_backup_selection" "cwa" {
  name         = "${local.application_name_short}-backup"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSBackup"
  plan_id      = aws_backup_plan.cwa.id
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/snapshot-with-daily-35-day-retention"
      value = "yes"
    }
  }
}

data "aws_iam_policy_document" "cwa_vault" {
  statement {
    sid    = "Allow local account basic permissions to the vault"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"]
    }

    actions = [
      "backup:DescribeBackupVault",
      "backup:PutBackupVaultAccessPolicy",
      "backup:DeleteBackupVaultAccessPolicy",
      "backup:GetBackupVaultAccessPolicy",
      "backup:StartBackupJob",
      "backup:GetBackupVaultNotifications",
      "backup:PutBackupVaultNotifications",
      "backup:StartRestoreJob"
    ]

    resources = [aws_backup_vault.cwa.arn]
  }
  statement {
    sid    = "Allow copying of recovery points from Landing Zone"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.application_data.accounts[local.environment].lz_account_id}:root"]
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = [aws_backup_vault.cwa.arn]
  }
}

resource "aws_backup_vault_policy" "cwa" {
  backup_vault_name = aws_backup_vault.cwa.name
  policy            = data.aws_iam_policy_document.cwa_vault.json
}