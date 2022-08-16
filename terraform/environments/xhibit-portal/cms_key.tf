#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
# Only created in Test account currently as AMIs encrypted using this key
# should be shared with Production account, hence Prod account requires permissions
# to use this key
#------------------------------------------------------------------------------

resource "aws_kms_key" "xhibit-cmk" {
  count                   = local.environment == "development" ? 1 : 0
  description             = "Xhibit Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.shared_cmk_policy[0].json
  enable_key_rotation     = true
}

resource "aws_kms_alias" "xhibit-cmk-alias" {
  count         = local.environment == "development" ? 1 : 0
  name          = "alias/xhibit-shared-key"
  target_key_id = aws_kms_key.xhibit-cmk[0].key_id
}

data "aws_iam_policy_document" "shared_cmk_policy" {
  count = local.environment == "development" ? 1 : 0
  statement {
    effect = "Allow"
    actions = ["kms:Encrypt",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    # these can be ignored as this policy is being applied to a specific key resource. ["*"] in this case refers to this key
    #tfsec:ignore:aws-iam-no-policy-wildcards
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["xhibit-portal-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["xhibit-portal-preproduction"]}:root",
      ]
    }
  }
  statement {
    effect = "Allow"
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
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    # these can be ignored as this policy is being applied to a specific key resource. ["*"] in this case refers to this key
    #tfsec:ignore:aws-iam-no-policy-wildcards
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"]
    }
  }
}

