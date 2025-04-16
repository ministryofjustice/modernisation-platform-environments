#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
#------------------------------------------------------------------------------

resource "aws_kms_key" "xhibit-cmk" {
  description         = "Xhibit Managed Key for AMI Sharing"
  policy              = local.is-development ? data.aws_iam_policy_document.shared_cmk_policy[0].json : ""
  enable_key_rotation = true
}

resource "aws_kms_alias" "xhibit-cmk-alias" {
  name          = "alias/xhibit-shared-key"
  target_key_id = aws_kms_key.xhibit-cmk.key_id
}

data "aws_iam_policy_document" "shared_cmk_policy" {

  # checkov:skip=CKV_AWS_109: "Key policy requires asterisk resource"
  # checkov:skip=CKV_AWS_111: "Key policy requires asterisk resource"
  # checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"

  count = local.is-development ? 1 : 0
  statement {
    sid     = "Enable IAM User Permissions"
    actions = ["kms:*"]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.id)]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow access from remote account"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_9a5e04597105d217", local.environment_management.account_ids["xhibit-portal-preproduction"]), format("arn:aws:iam::%s:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_570eb7336a1416a0", local.environment_management.account_ids["xhibit-portal-production"])]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)]), format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-preproduction", local.application_name)])]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow attachment of persistent resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)]), format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-preproduction", local.application_name)])]
      type        = "AWS"
    }
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
    resources = ["*"]
  }
}
