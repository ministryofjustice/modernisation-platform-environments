data "aws_route53_zone" "application-zone" {
  provider = aws.core-network-services

  name         = "equip.service.justice.gov.uk."
  private_zone = false
}

data "aws_iam_policy_document" "kms_policy" {

  # checkov:skip=CKV_AWS_109: "Key policy requires asterisk resource"
  # checkov:skip=CKV_AWS_111: "Key policy requires asterisk resource"

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
      identifiers = [format("arn:aws:iam::%s:role/ModernisationPlatformAccess", local.environment_management.account_ids["equip-production"])]
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
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)])]
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
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)])]
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
