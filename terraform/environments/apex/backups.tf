############################################################################
## This file is used to create a backup vault for migrating EFS data only
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
