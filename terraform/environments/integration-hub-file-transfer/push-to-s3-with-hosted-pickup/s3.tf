module "s3_hosted_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.4"

  for_each = local.hosted_pickup_entries

  bucket = local.hosted_bucket_names[each.key]

  allowed_kms_key_arn                      = module.kms_hosted_pickup[each.key].key_arn
  attach_deny_incorrect_encryption_headers = true
  attach_deny_incorrect_kms_key_sse        = true
  attach_deny_insecure_transport_policy    = true
  attach_deny_unencrypted_object_uploads   = true
  attach_require_latest_tls_policy         = true
  block_public_acls                        = true
  block_public_policy                      = true
  control_object_ownership                 = true
  ignore_public_acls                       = true
  object_ownership                         = "BucketOwnerEnforced"
  restrict_public_buckets                  = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_hosted_pickup[each.key].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [{
    id     = "configured-retention"
    status = "Enabled"
    filter = {}
    expiration = {
      days = each.value.action.push_to_s3_with_hosted_pickup.retention_days
    }
    noncurrent_version_expiration = {
      noncurrent_days = each.value.action.push_to_s3_with_hosted_pickup.retention_days
    }
    abort_incomplete_multipart_upload_days = 1
  }]

  versioning = {
    status     = true
    mfa_delete = false
  }

  tags = local.tags
}