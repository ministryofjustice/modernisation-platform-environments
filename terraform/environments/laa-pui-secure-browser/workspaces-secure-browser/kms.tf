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

  dynamic "statement" {
    for_each = local.create_resources ? [1] : []
    content {
      sid = "AllowCortexXSIAMRoleUseKey"
      principals {
        type        = "AWS"
        identifiers = [module.cortex_xsiam_role[0].arn]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.create_resources ? [1] : []
    content {
      sid = "AllowCloudWatchUseKey"
      principals {
        type        = "Service"
        identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
        "kms:CreateGrant"
      ]
      resources = ["*"]
    }
  }
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

resource "aws_kms_alias" "workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  name          = "alias/workspacesweb-session-logs"
  target_key_id = aws_kms_key.workspacesweb_session_logs[0].key_id
}
