# Only create one role per account
resource "aws_iam_role" "aws_backup_default_service_role" {
  count = contains(["poc", "stage"], var.env_name) ? 0 : 1
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
  count      = contains(["poc", "stage"], var.env_name) ? 0 : 1
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count      = contains(["poc", "stage"], var.env_name) ? 0 : 1
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
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
      var.account_config.kms_keys.general_shared,
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  count  = contains(["poc", "stage"], var.env_name) ? 0 : 1
  name   = "${var.env_name}-${var.db_suffix}-business-unit-kms-key-access-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
}

resource "aws_iam_role_policy_attachment" "backup_service_kms_policy_attachment" {
  count      = contains(["poc", "stage"], var.env_name) ? 0 : 1
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = aws_iam_policy.business_unit_kms_key_access[0].arn
}
