module "s3_sftp_readback" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  create_bucket = local.create_test_harness
  bucket        = local.sftp_bucket_name
  force_destroy = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # Holds copies of throw-away test files only, so S3-managed encryption is enough.
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    status = true
  }

  lifecycle_rule = [
    {
      id     = "expire-test-files"
      status = "Enabled"
      filter = {}

      expiration = {
        days = 1
      }

      noncurrent_version_expiration = {
        noncurrent_days = 1
      }

      abort_incomplete_multipart_upload_days = 1
    },
    {
      id     = "remove-expired-delete-markers"
      status = "Enabled"
      filter = {}

      expiration = {
        expired_object_delete_marker = true
      }
    }
  ]

  tags = local.tags
}
