### IAM ROLE FOR WORKSPACES WEB SESSION LOGGING

resource "aws_iam_role" "workspacesweb_session_logging" {
  name = "workspacesweb-session-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "workspaces-web.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-session-logging-role"
    }
  )
}

resource "aws_iam_role_policy" "workspacesweb_session_logging" {
  name = "workspacesweb-session-logging-policy"
  role = aws_iam_role.workspacesweb_session_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          module.s3_bucket_workspacesweb_session_logs.s3_bucket_arn,
          "${module.s3_bucket_workspacesweb_session_logs.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

### KMS KEY FOR SESSION LOGGING ENCRYPTION (OPTIONAL)

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