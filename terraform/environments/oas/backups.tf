locals {
  cold_storage_after = 30
}

resource "aws_backup_vault" "default" {
  name = "everything"
  tags = var.tags
}

# Non production backups
resource "aws_backup_plan" "non_production" {
  name = "backup-daily-cold-storage-monthly-retain-30-days"

  rule {
    rule_name         = "backup-daily-cold-storage-monthly-retain-30-days"
    target_vault_name = aws_backup_vault.default.name

    # Backup every day at 00:30am
    schedule = "cron(30 0 * * ? *)"

    # The amount of time in minutes to start and finish a backup
    ## Start the backup within 1 hour of the schedule
    start_window = (1 * 60)
    ## Complete the backup within 6 hours of starting
    completion_window = (6 * 60)

    lifecycle {
      delete_after = 30
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }

  tags = var.tags
}

resource "aws_backup_selection" "non_production" {
  name         = "non-production-backup"
  iam_role_arn = var.iam_role_arn
  plan_id      = aws_backup_plan.non_production.id
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/backup"
      value = "true"
    }
    string_not_equals {
      key   = "aws:ResourceTag/is-production"
      value = "true"
    }
  }
}