resource "aws_backup_vault" "default_backup_vault" {
    name = format("%s-openldap-efs-backup-vault", local.application_name)
    tags = {
        Name = format("%s-openldap-efs-backup-vault", local.application_name)
    }
}

resource "aws_backup_plan" "ldap_backup_plan" {
    name = format("%s-openldap-efs-backup", local.application_name)

    rule {
        rule_name         = "${local.application_name}-openldap-efs-backup-retain-${local.application_data.accounts[local.environment].efs_backup_retention_period}-days"
        target_vault_name = aws_backup_vault.default_backup_vault.name
        
        schedule = local.application_data.accounts[local.environment].efs_backup_schedule

        # The amount of time in minutes to start and finish a backup
        ## Start the backup within 1 hour of the schedule
        start_window = (1 * 60)
        ## Complete the backup within 6 hours of starting
        #completion_window = (6 * 60)
        
        lifecycle {
            delete_after = local.application_data.accounts[local.environment].efs_backup_retention_period
        }
    }
    
    tags = merge(
        local.tags,
        {
            Name = format("%s-openldap-efs-backup-plan", local.application_name)
        },
    )
}

resource "aws_backup_selection" "efs_backup" {
    name         = format("%s-openldap-efs", local.application_name)
    iam_role_arn = aws_iam_role.efs_backup_role.arn
    plan_id      = aws_backup_plan.ldap_backup_plan.id
    resources    = [
        aws_efs_file_system.openldap.arn
    ]
}

##
# IAM role and policy for EFS Backups implementation
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
    name = format("%s-openldap-efs-backup-role", local.application_name)
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
            "backup:ListBackupPlanTemplates",
            "backup:DescribeRestoreJob",
            "backup:GetRecoveryPointRestoreMetadata",
            "backup:ListRestoreJobs",
            "backup:StartRestoreJob"
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
            "efs:DescribeTags",
            "elasticfilesystem:Backup",
            "elasticfilesystem:DescribeTags",
            "elasticfilesystem:CreateAccessPoint",
            "elasticfilesystem:CreateFileSystem",
            "elasticfilesystem:CreateMountTarget",
            "elasticfilesystem:DeleteAccessPoint",
            "elasticfilesystem:DeleteFileSystem",
            "elasticfilesystem:DeleteMountTarget",
            "elasticfilesystem:DescribeAccessPoints",
            "elasticfilesystem:DescribeFileSystemPolicy",
            "elasticfilesystem:DescribeFileSystems",
            "elasticfilesystem:DescribeLifecycleConfiguration",
            "elasticfilesystem:DescribeMountTargets",
            "elasticfilesystem:DescribeMountTargetSecurityGroups",
            "elasticfilesystem:PutBackupPolicy",
            "elasticfilesystem:PutFileSystemPolicy",
            "elasticfilesystem:PutLifecycleConfiguration",
            "elasticfilesystem:Restore",
            "elasticfilesystem:TagResource",
            "elasticfilesystem:UntagResource",
            "elasticfilesystem:UpdateFileSystem"
        ]
    }
}

resource "aws_iam_role_policy" "efs_backups" {
    name   = format("%s-efs-backup-policy", local.application_name)
    policy = data.aws_iam_policy_document.efs_backup_policy.json
    role   = aws_iam_role.efs_backup_role.id
}
