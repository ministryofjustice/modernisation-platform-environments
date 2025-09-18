### KMS KEY FOR SESSION LOGGING ENCRYPTION

resource "aws_kms_key" "workspacesweb_session_logs" {
  description             = "KMS key for WorkSpaces Web session logs encryption"
  deletion_window_in_days = 7

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
        Sid    = "Allow WorkSpaces Web to use the key"
        Effect = "Allow"
        Principal = {
          Service = "workspaces-web.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-session-logs-key"
    }
  )
}

resource "aws_kms_alias" "workspacesweb_session_logs" {
  name          = "alias/workspacesweb-session-logs"
  target_key_id = aws_kms_key.workspacesweb_session_logs.key_id
}