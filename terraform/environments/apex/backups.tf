############################################################################
## This following is used to create a backup vault for migrating EFS data only
## Resources here can be removed after data migration
############################################################################

resource "aws_backup_vault" "apex" {
  name = "${local.application_name}-backup-vault"
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-backup-vault" },
  )
}

data "aws_iam_policy_document" "apex" {
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

    resources = [aws_backup_vault.apex.arn]
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

    resources = [aws_backup_vault.apex.arn]
  }
}

resource "aws_backup_vault_policy" "apex" {
  backup_vault_name = aws_backup_vault.apex.name
  policy            = data.aws_iam_policy_document.apex.json
}

############################################################################
## This following is required for setting up backup for production
############################################################################


resource "aws_backup_vault" "prod_apex" {
  count = local.environment == "production" ? 1 : 0
  name  = "${local.application_name}-production-backup-vault"
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-production-backup-vault" },
  )
}

resource "aws_backup_plan" "prod_apex" {
  count = local.environment == "production" ? 1 : 0
  name  = "${local.application_name}-backup-retain-35-days"

  rule {
    rule_name         = "${local.application_name}-backup-retain-35-days"
    target_vault_name = aws_backup_vault.prod_apex[0].name

    # Backup every 6 hours on the hour
    schedule = "cron(0 0,6,12,18 * * ? *)"

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
    { "Name" = "${local.application_name}-backup-plan" },
  )
}

resource "aws_backup_selection" "prod_apex" {
  count        = local.environment == "production" ? 1 : 0
  name         = "${local.application_name}-production-backup"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSBackup"
  plan_id      = aws_backup_plan.prod_apex[0].id
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/snapshot-35-day-retention"
      value = "yes"
    }
    # TODO tags required to be confirmed
    # string_equals {
    #   key   = "aws:ResourceTag/is-production"
    #   value = "true"
    # }
  }
}