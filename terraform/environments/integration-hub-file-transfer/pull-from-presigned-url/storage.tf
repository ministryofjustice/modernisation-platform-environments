data "aws_kms_key" "clean" { key_id = "alias/s3/clean" }

module "s3_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source                                   = "terraform-aws-modules/s3-bucket/aws"
  version                                  = "5.16.1"
  bucket                                   = local.pickup_bucket_name
  allowed_kms_key_arn                      = module.kms_notifications_pipeline.key_arn
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
  attach_policy                            = true
  policy                                   = data.aws_iam_policy_document.pickup_age.json
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_notifications_pipeline.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning = { status = true, mfa_delete = false }
  lifecycle_rule = [{
    id                                     = "seven-day-pickup"
    status                                 = "Enabled"
    filter                                 = {}
    expiration                             = { days = 7 }
    noncurrent_version_expiration          = { noncurrent_days = 7 }
    abort_incomplete_multipart_upload_days = 1
  }]
  tags = local.tags
}

data "aws_iam_policy_document" "pickup_age" {
  statement {
    sid       = "DenySignaturesOlderThanFiveMinutes"
    effect    = "Deny"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${local.pickup_bucket_name}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericGreaterThan"
      variable = "s3:signatureAge"
      values   = ["300000"]
    }
  }
}
