locals {
  cold_storage_after = 30
}

resource "aws_backup_vault" "default_oas" {
  name =  "${local.application_name}-backup-vault"
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-backup-vault" },
  )
}

# Non production backups
resource "aws_backup_plan" "non_production_oas" {

  name = "${local.application_name}-backup-daily-retain-30-days"

  rule {
    rule_name         = "${local.application_name}-backup-daily-retain-30-days"
    target_vault_name = aws_backup_vault.default_oas.name

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

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-backup-plan" },
  )
}

resource "aws_backup_selection" "non_production_oas" {
  name         = "${local.application_name}-non-production-backup"
  iam_role_arn = local.application_data.accounts[local.environment].iam_role_arn
  plan_id      = aws_backup_plan.non_production_oas.id
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