#------------------------------------------------------------------------------
# Customer Managed Keys
#------------------------------------------------------------------------------

data "aws_kms_key" "default_ebs" {
  key_id = "alias/aws/ebs"
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
  description             = "Nomis-managed key for encrypton of SNS topic"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.sns_topic_key_policy.json
}

resource "aws_kms_alias" "sns" {
  name          = "alias/nomis-sns-encryption"
  target_key_id = aws_kms_key.sns.key_id
}
