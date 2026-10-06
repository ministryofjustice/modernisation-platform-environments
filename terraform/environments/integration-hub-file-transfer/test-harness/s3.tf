module "s3_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  create_bucket = local.create_test_harness
  bucket        = "${local.application_name}-${local.environment}-${local.component_name}"
  force_destroy = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  allowed_kms_key_arn                      = module.kms_test_harness.key_arn
  attach_deny_incorrect_encryption_headers = true
  attach_deny_incorrect_kms_key_sse        = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_test_harness.key_arn
        sse_algorithm     = "aws:kms"
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

moved {
  from = module.destination
  to   = module.s3_test_harness
}