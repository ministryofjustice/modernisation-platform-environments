data "aws_iam_policy_document" "gc_pdc_token_kms" {
  provider = aws.policy
}

data "aws_iam_policy_document" "gc_pdc_token_secret" {
  provider = aws.policy
}
