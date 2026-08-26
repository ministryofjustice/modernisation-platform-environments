resource "aws_backup_vault" "ldap_backup_vault" {
  #checkov:skip=CKV_AWS_166
  name = "${var.env_name}-ldap-efs-vault"
  tags = merge(
    var.tags,
    {
      Name = "${var.env_name}-ldap-efs-vault"
    },
  )
}

resource "aws_backup_plan" "ldap_backup_plan" {
  name = "${var.env_name}-ldap-efs-plan"

  rule {
    rule_name         = "${var.env_name}-ldap-efs-retain-${var.ldap_config.efs_backup_retention_period}-days"
    target_vault_name = aws_backup_vault.ldap_backup_vault.name

    schedule = var.ldap_config.efs_backup_schedule

    # The amount of time in minutes to start and finish a backup
    ## Start the backup within 1 hour of the schedule
    start_window = (1 * 60)
    ## Complete the backup within 6 hours of starting
    #completion_window = (6 * 60)

    lifecycle {
      delete_after = var.ldap_config.efs_backup_retention_period
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.env_name}-ldap-efs-plan"
    },
  )
}

resource "aws_backup_selection" "efs_backup" {
  name         = "${var.env_name}-ldap-efs"
  iam_role_arn = aws_iam_role.ldap_efs_backup_role.arn
  plan_id      = aws_backup_plan.ldap_backup_plan.id
  resources = [
    module.efs.fs_arn
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

resource "aws_iam_role" "ldap_efs_backup_role" {
  name               = "${var.env_name}-ldap-efs-awsbackup-role"
  assume_role_policy = data.aws_iam_policy_document.delius_core_backup.json
  tags               = var.tags
}

data "aws_iam_policy_document" "delius_core_backup_policy" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_356
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
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
  name   = "${var.env_name}-awsbackup-policy"
  policy = data.aws_iam_policy_document.delius_core_backup_policy.json
  role   = aws_iam_role.ldap_efs_backup_role.id
}

data "aws_iam_policy_document" "efs_backup_policy" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_356
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
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
  name   = "${var.env_name}-efs-awsbackup-policy"
  policy = data.aws_iam_policy_document.efs_backup_policy.json
  role   = aws_iam_role.ldap_efs_backup_role.id
}
