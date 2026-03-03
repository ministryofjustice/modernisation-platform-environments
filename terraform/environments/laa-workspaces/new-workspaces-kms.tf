##############################################
### KMS Key for WorkSpaces Volume Encryption
##############################################

resource "aws_kms_key" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  description             = "KMS key for WorkSpaces volume encryption - ${local.application_name}-${local.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow WorkSpaces Service"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.workspaces_default[0].arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-workspaces-kms" }
  )
}

resource "aws_kms_alias" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  name          = "alias/${local.application_name}-${local.environment}-workspaces"
  target_key_id = aws_kms_key.workspaces[0].key_id
}
