#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
# Only created in Test account currently as AMIs encrypted using this key
# should be shared with Production account, hence Prod account requires permissions
# to use this key
#------------------------------------------------------------------------------

resource "aws_kms_key" "oasys-cmk" {
  count                   = local.environment == "test" ? 1 : 0
  description             = "oasys Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.shared_image_builder_cmk_policy[0].json
  enable_key_rotation     = true
}

resource "aws_kms_alias" "oasys-key" {
  count         = local.environment == "test" ? 1 : 0
  name          = "alias/oasys-image-builder"
  target_key_id = aws_kms_key.oasys-cmk[0].key_id
}

data "aws_iam_policy_document" "shared_image_builder_cmk_policy" {
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
      identifiers = ["arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-development"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-preproduction"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-production"]}:root",
        "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "sns_topic_key_policy" {
  policy_id = "sns-topic-cmk-policy"
  statement {
    sid = "Enable IAM User Permissions for administration of this key"
    actions = [
      "kms:*", # for key management
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    # these can be ignored as this policy is being applied to a specific key resource. ["*"] in this case refers to this key
    #tfsec:ignore:aws-iam-no-policy-wildcards
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"]
  }
}

resource "aws_kms_key" "sns" {
  description             = "oasys-managed key for encrypton of SNS topic"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.sns_topic_key_policy.json
}

resource "aws_kms_alias" "sns" {
  name          = "alias/oasys-sns-encryption"
  target_key_id = aws_kms_key.sns.key_id
}
