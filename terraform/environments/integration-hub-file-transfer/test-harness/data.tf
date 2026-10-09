data "aws_s3_bucket" "incoming" {
  count = local.create_test_harness ? 1 : 0

  bucket = local.incoming_bucket_name
}

data "aws_kms_key" "incoming" {
  count = local.create_test_harness ? 1 : 0

  key_id = local.incoming_kms_key_alias
}