# Create the AWS Backup Vault and attach the KMS key
resource "aws_backup_vault" "yjaf_backup_vault" {
  name        = "yjaf-backup-vault"
  kms_key_arn = aws_kms_key.backup_kms_key.arn
}

resource "aws_backup_plan" "yjaf_backup_plan" {
  name = "yjaf-backup-plan"

  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.yjaf_backup_vault.name
    schedule          = "cron(0 21 ? * * *)"
    start_window      = 60
    completion_window = 480
    lifecycle {
      delete_after = 14
    }
  }

  rule {
    rule_name         = "Monthly-backup-6-retention"
    target_vault_name = aws_backup_vault.yjaf_backup_vault.name
    schedule          = "cron(0 5 1 * ? *)"
    start_window      = 480
    completion_window = 10080
    lifecycle {
      cold_storage_after = 30
      delete_after       = 180
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.yjaf_backup_vault.name
    schedule          = "cron(30 0 ? * 7 *)"
    start_window      = 480
    completion_window = 10080
    lifecycle {
      delete_after = 28
    }
  }
}

resource "aws_backup_selection" "linux_backup_selection" {
  name         = "linux-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn # Updated role reference

  resources = [
    "arn:aws:ec2:*:*:instance/*"
  ]
}

resource "aws_backup_selection" "windows_backup_selection" {
  name         = "windows-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn # Updated role reference

  resources = [
    "arn:aws:ec2:*:*:instance/*"
  ]
}

resource "aws_backup_selection" "rds_backup_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.yjaf_backup_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn # Updated role reference

  resources = [
    "arn:aws:rds:*:*:db:*"
  ]
}

# IAM Role for AWS Backup
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

resource "aws_iam_policy" "backup_selection_permissions" {
  name        = "BackupSelectionPermissions"
  description = "Permissions for AWS Backup, including scoped backup access and storage"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "backup:StartBackupJob",
          "backup:StartCopyJob",
          "backup:StartRestoreJob",
          "backup:GetBackupVaultAccessPolicy",
          "backup:GetBackupVaultNotifications",
          "backup:ListBackupJobs",
          "backup:ListBackupVaults"
        ],
        Resource = aws_backup_vault.yjaf_backup_vault.arn
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" : "<region>"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "backup-storage:MountCapsule"
        ],
        Resource = aws_backup_vault.yjaf_backup_vault.arn
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
          "rds:ListTagsForResource"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:RetireGrant",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.backup_kms_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_selection_permissions_attachment" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.backup_selection_permissions.arn
}

resource "aws_iam_policy" "secrets_kms_policy" {
  name        = "SecretsManagerKMSAccess"
  description = "Policy to access SecretsManager secrets and KMS keys for backups"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:backup/*"
        ],
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" : data.aws_region.current.name
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.backup_kms_key.arn,
        Condition = {
          StringEquals = {
            "kms:ViaService" : "backup.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_kms_policy_attachment" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.secrets_kms_policy.arn
}


resource "aws_kms_key" "backup_kms_key" {
  description             = "KMS key for encrypting AWS Backup vault"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "backup_kms_policy" {
  key_id = aws_kms_key.backup_kms_key.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow AWS Backup Service to use the key
      {
        Sid    = "AllowBackupServiceAccess",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.backup_kms_key.arn
      },
      # Allow Full Access (Prevents Lockout)
      {
        Sid    = "AllowAccountRootUserFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = aws_kms_key.backup_kms_key.arn
      }
    ]
  })
}

# Create an alias for easier identification
resource "aws_kms_alias" "backup_kms_alias" {
  name          = "alias/aws-backup-key"
  target_key_id = aws_kms_key.backup_kms_key.key_id
}
