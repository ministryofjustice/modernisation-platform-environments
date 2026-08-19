locals {
  async_transcription_bucket_name = "mojdp-${local.environment}-${local.component_name}-justice-transcribe-async"
}

module "async_transcription" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c526035d69d47b68ac896cb5f98c18b21074edae" # v5.15.1

  bucket = local.async_transcription_bucket_name

  force_destroy = false

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.justice_transcribe_async_kms_key[0].key_arn
      }
      bucket_key_enabled = true
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [
    {
      id     = "expire-objects-after-seven-days"
      status = "Enabled"
      filter = {}
      expiration = {
        days = 7
      }
      noncurrent_version_expiration = {
        noncurrent_days = 7
      }
    }
  ]
}
