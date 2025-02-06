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