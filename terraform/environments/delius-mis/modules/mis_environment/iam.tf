data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid = "SecretPermissions"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.ad_admin_password.arn,
      "arn:aws:secretsmanager:*:*:secret:NDMIS_DFI_SERVICEACCOUNTS_${upper(var.env_name)}-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-oracle-mis-db-application-passwords-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-oracle-dsd-db-application-passwords-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-oracle-boe-db-application-passwords-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-sap-boe-config-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-sap-boe-passwords-*"
    ]
  }

  statement {
    sid = "SecretPermissionsPut"
    actions = [
      "secretsmanager:PutSecretValue"
    ]
    resources = [
      # secrets are directly updated by ansible code
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-sap-boe-config-*",
      "arn:aws:secretsmanager:*:*:secret:${var.app_name}-${var.env_name}-sap-boe-passwords-*"
    ]
  }
}

resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.env_name}-read-access-to-secrets"
  path        = "/"
  description = "Allow ec2 instance to read secrets"
  policy      = data.aws_iam_policy_document.secrets_manager.json

  tags = var.tags
}

data "aws_iam_policy_document" "ec2_automation" {
  statement {
    sid = "EC2AutomationPermissions"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "s3:GetObject",
      "s3:ListBucket",
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_automation" {
  name        = "${var.env_name}-ec2-automation-instances"
  path        = "/"
  description = "Allow ec2 instance to run automation"
  policy      = data.aws_iam_policy_document.ec2_automation.json

  tags = var.tags
}

# AWS Backup Role
resource "aws_iam_role" "aws_backup_default_service_role" {
  count = var.create_backup_role ? 1 : 0
  name  = "AWSBackupDefaultServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
  count = var.create_backup_role ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      var.account_config.kms_keys.general_shared
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  count  = var.create_backup_role ? 1 : 0
  name   = "${var.env_name}-business-unit-kms-key-access-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access[0].json
}

resource "aws_iam_role_policy_attachment" "backup_service_kms_policy_attachment" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = aws_iam_policy.business_unit_kms_key_access[0].arn
}
