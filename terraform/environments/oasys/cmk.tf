

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
