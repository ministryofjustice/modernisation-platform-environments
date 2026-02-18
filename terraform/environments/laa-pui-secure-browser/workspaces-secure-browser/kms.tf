### KMS KEY FOR WORKSPACES WEB SESSION LOGGING

data "aws_partition" "current" {}

data "aws_iam_policy_document" "kms_key_policy" {
  #checkov:skip=CKV_AWS_109:Policy authored in line with existing guidance
  #checkov:skip=CKV_AWS_111:Irrelevant; this is a KMS key policy, not an IAM policy
  #checkov:skip=CKV_AWS_356:Wildcard necessary, suitable constraints in place
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

  # Derived from https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
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
        "kms:Describe*"
      ]
      resources = ["*"]
      condition {
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
        ]
      }
    }
  }
}

resource "aws_kms_key" "workspacesweb_session_logs" {
  #checkov:skip=CKV_AWS_7
  #checkov:skip=CKV_AWS_109:Policy authored in line with existing guidance
  #checkov:skip=CKV_AWS_111:Irrelevant; this is a KMS key policy, not an IAM policy
  #checkov:skip=CKV_AWS_356:Wildcard necessary, suitable constraints in place
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
