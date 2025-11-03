### KMS KEY FOR WORKSPACES WEB SESSION LOGGING

data "aws_partition" "current" {}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

moved {
  from = aws_kms_key.workspacesweb_session_logs
  to   = aws_kms_key.workspacesweb_session_logs[0]
}

resource "aws_kms_key" "workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  description = "KMS key for WorkSpaces Web Session Logger"
  policy      = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-session-logs-key"
    }
  )
}

moved {
  from = aws_kms_alias.workspacesweb_session_logs
  to   = aws_kms_alias.workspacesweb_session_logs[0]
}

resource "aws_kms_alias" "workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  name          = "alias/workspacesweb-session-logs"
  target_key_id = aws_kms_key.workspacesweb_session_logs[0].key_id
}

### KMS KEY FOR SECURE BROWSER S3 BUCKET

data "aws_iam_policy_document" "kms_secure_browser_bucket_policy" {
  count = local.create_resources ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "secure_browser_bucket" {
  count = local.create_resources ? 1 : 0

  description             = "KMS key for Secure Browser S3 Bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_secure_browser_bucket_policy[0].json

  tags = merge(
    local.tags,
    {
      Name = "secure-browser-bucket-key"
    }
  )
}

resource "aws_kms_alias" "secure_browser_bucket" {
  count = local.create_resources ? 1 : 0

  name          = "alias/secure-browser-bucket"
  target_key_id = aws_kms_key.secure_browser_bucket[0].key_id
}
