#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
# Only created in Test account currently as AMIs encrypted using this key
# should be shared with Production account, hence Prod account requires permissions
# to use this key
#------------------------------------------------------------------------------

resource "aws_kms_key" "nomis-cmk" {
  count                   = local.environment == "test" ? 1 : 0
  description             = "Nomis Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.shared_image_builder_cmk_policy[0].json
  enable_key_rotation     = true
}

resource "aws_kms_alias" "nomis-key" {
  count         = local.environment == "test" ? 1 : 0
  name          = "alias/nomis-image-builder"
  target_key_id = aws_kms_key.nomis-cmk[0].key_id
}

data "aws_iam_policy_document" "shared_image_builder_cmk_policy" {
  count = local.environment == "test" ? 1 : 0
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
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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