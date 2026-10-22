module "github_backup_key" {
  count = local.is_production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=af1d45558a6073c017a732d2273efcc733b34d0f" # v4.2.1

  aliases                 = ["github-backup"]
  description             = "Encrypt GitHub repository backup archives"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

module "github_backup_bucket" {
  count = local.is_production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=dd0c434de5e74d8864e249ee020d917b076b6e32" # v5.15.4

  bucket        = local.github_backup_bucket_name
  force_destroy = false

  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.github_backup_key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
}
