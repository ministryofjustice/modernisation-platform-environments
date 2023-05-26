resource "aws_backup_vault" "portal" {
  name = "${local.application_name}-backup-vault"
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-backup-vault" },
  )
}

# Non production backups
resource "aws_backup_plan" "non_prod_portal" {

  name = "${local.application_name}-backup-daily-retain-35-days"

  rule {
    rule_name         = "${local.application_name}-backup-daily-retain-35-days"
    target_vault_name = aws_backup_vault.portal.name

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
    { "Name" = "${local.application_name}backup-plan" },
  )
}

resource "aws_backup_selection" "non_prod_portal" {
  name         = "${local.application_name}non-production-backup"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSBackup"
  plan_id      = aws_backup_plan.non_prod_portal.id
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/snapshot-with-daily-35-day-retention"
      value = "yes"
    }
    string_not_equals {
      key   = "aws:ResourceTag/is-production"
      value = "true"
    }
  }
}
