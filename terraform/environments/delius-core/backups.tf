resource "aws_backup_vault" "default_openldap" {
  name = format("%s-openldap", local.application_name)
  tags = {
    Name = format("%s-openldap", local.application_name)
  }
}

# Non production backup plan
#resource "aws_backup_plan" "efs_backup_plan" {
#
#  name = "${local.application_name}-efs-backup-plan"
#
#  rule {
#    rule_name         = "${local.application_name}-backup-daily-retain-7-days"
#    target_vault_name = aws_backup_vault.default_oas.name
#
#    # Backup every day at 12:00am
#    schedule = "cron(0 0 * * ? *)"
#
#    # The amount of time in minutes to start and finish a backup
#    ## Start the backup within 1 hour of the schedule
#    start_window = (1 * 60)
#    ## Complete the backup within 6 hours of starting
#    completion_window = (6 * 60)
#
#    lifecycle {
#      delete_after = 7
#    }
#  }
#
#  advanced_backup_setting {
#    backup_options = {
#      WindowsVSS = "enabled"
#    }
#    resource_type = "EC2"
#  }
#
#  tags = merge(
#    local.tags,
#    { "Name" = "${local.application_name}-backup-plan" },
#  )
#}
#
#resource "aws_backup_selection" "non_production_oas" {
#  name         = "${local.application_name}-non-production-backup"
#  iam_role_arn = local.application_data.accounts[local.environment].iam_role_arn
#  plan_id      = aws_backup_plan.non_production_oas.id
#  resources    = ["*"]
#
#  condition {
#    string_equals {
#      key   = "aws:ResourceTag/snapshot-with-daily-7-day-retention"
#      value = "yes"
#    }
#    string_not_equals {
#      key   = "aws:ResourceTag/is-production"
#      value = "true"
#    }
#  }
#}

##
# IAM role and policy creation for EFS Backups
##
data "aws_iam_policy_document" "delius_core_backup" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "efs_backup_role" {
  name = format("%s-efs-backup-role", local.application_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_backup.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_core_backup_policy" {
    statement {
        effect = "Allow"
        resources = ["*"]

        actions =[
            "backup:CreateBackupPlan",
            "backup:CreateBackupSelection",
            "backup:StartBackupJob",
            "backup:DescribeBackupJob",
            "backup:ListBackupJobs",
            "backup:ListBackupVaults",
            "backup:ListRecoveryPointsByBackupVault",
            "backup:ListBackupPlanTemplates"
        ]
    }
}

resource "aws_iam_role_policy" "delius_core_backups" {
    name   = format("%s-backup-policy", local.application_name)
    policy = data.aws_iam_policy_document.delius_core_backup_policy.json
    role   = aws_iam_role.efs_backup_role.id
}

data "aws_iam_policy_document" "efs_backup_policy" {
    statement {
        effect = "Allow"
        resources = ["*"]

        actions =[
            "efs:DescribeFileSystems",
            "efs:CreateBackup",
            "efs:DeleteBackup",
            "efs:DescribeBackups",
            "efs:CreateTags",
            "efs:UntagResource",
            "efs:TagResource",
            "efs:DescribeTags"
        ]
    }
}

resource "aws_iam_role_policy" "efs_backups" {
    name   = format("%s-efs-backup-policy", local.application_name)
    policy = data.aws_iam_policy_document.efs_backup_policy.json
    role   = aws_iam_role.efs_backup_role.id
}
