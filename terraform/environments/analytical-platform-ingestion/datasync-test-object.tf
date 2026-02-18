# Create a test object in the bucket for DataSync to verify access against
resource "aws_s3_object" "datasync_test" {
  bucket  = module.datasync_opg_bucket.s3_bucket_id
  key     = ".datasync-test"
  content = "DataSync access test object"

  server_side_encryption = "aws:kms"
  kms_key_id             = module.s3_datasync_opg_kms.key_arn

  tags = local.tags

  depends_on = [
    module.datasync_opg_bucket,
    module.s3_datasync_opg_kms
  ]
}
