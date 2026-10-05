data "aws_s3_bucket" "incoming" {
  count = local.create_test_harness ? 1 : 0

  bucket = "${local.application_name}-${local.environment}-incoming"
}

data "aws_kms_key" "incoming" {
  count = local.create_test_harness ? 1 : 0

  key_id = "alias/s3/incoming"
}