data "aws_iam_policy_document" "s3_bucket" {
  count = local.is-production ? 1 : 0

  statement {
    sid    = "AllowBucketActions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions"
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
    principals {
      type        = "AWS"
      identifiers = [module.iam_role[0].arn]
    }
  }

  statement {
    sid    = "AllowObjectActions"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [module.iam_role[0].arn]
    }
  }
}

module "s3_bucket" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=dd0c434de5e74d8864e249ee020d917b076b6e32" # v5.15.4

  bucket = local.bucket_name

  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.s3_bucket[0].json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
}

module "github-backup" {
  count = local.is-production ? 1 : 0

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
        kms_master_key_id = module.github-backup-key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
}
