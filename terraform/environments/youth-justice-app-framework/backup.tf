resource "aws_backup_vault" "yjaf_backup_vault" {
  name = "yjaf-backup-vault"
}

resource "aws_backup_plan" "yjaf_backup_plan" {
  name = "yjaf-backup-plan"

  rule {
    rule_name                  = "DailyBackups"
    target_vault_name          = aws_backup_vault.yjaf_backup_vault.name
    schedule                   = "cron(0 21 ? * * *)"
    start_window               = 60
    completion_window          = 480
    lifecycle {
      delete_after = 14
    }
  }

  rule {
    rule_name                  = "Monthly-backup-6-retention"
    target_vault_name          = aws_backup_vault.yjaf_backup_vault.name
    schedule                   = "cron(0 5 1 * ? *)"
    start_window               = 480
    completion_window          = 10080
    lifecycle {
      cold_storage_after = 30
      delete_after       = 180
    }
  }

  rule {
    rule_name                  = "weekly-backup"
    target_vault_name          = aws_backup_vault.yjaf_backup_vault.name
    schedule                   = "cron(30 0 ? * 7 *)"
    start_window               = 480
    completion_window          = 10080
    lifecycle {
      delete_after = 28
    }
  }
}

resource "aws_backup_selection" "linux_backup_selection" {
  name         = "linux-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = "arn:aws:iam::066012302209:role/service-role/AWSBackupDefaultServiceRole"

  resources = [
    "arn:aws:ec2:*:*:instance/*"
  ]
}

resource "aws_backup_selection" "windows_backup_selection" {
  name         = "windows-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = "arn:aws:iam::066012302209:role/service-role/AWSBackupDefaultServiceRole"

  resources = [
    "arn:aws:ec2:*:*:instance/*"
  ]
}

resource "aws_backup_selection" "rds_backup_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = "arn:aws:iam::066012302209:role/service-role/AWSBackupDefaultServiceRole"

  resources = [
    "arn:aws:rds:*:*:db:*"
  ]
}



resource "aws_iam_role" "backup_role" {
  name = "aws-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}
