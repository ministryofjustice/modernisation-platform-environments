# Resolve the full key ARN through the stable cross-account alias.
data "aws_kms_key" "incoming" {
  key_id = "arn:aws:kms:eu-west-2:${local.mft_account_id}:alias/s3/incoming"
}
