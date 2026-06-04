locals {
  db_migration_name        = local.application_data.accounts[local.environment].db_migration_name
  db_migration_bucket_name = "cdpt-chaps-${local.application_data.accounts[local.environment].environment_name}-db-migration-${data.aws_caller_identity.current.account_id}"
  db_migration_prefix      = local.application_data.accounts[local.environment].db_migration_prefix
}

resource "aws_kms_key" "db_migration" {
  description             = "CHAPS ${local.environment} database migration S3 encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.db_migration_kms.json

  tags = local.tags
}

resource "aws_kms_alias" "db_migration" {
  name          = "alias/chaps-dev-db-migration"
  target_key_id = aws_kms_key.db_migration.key_id
}

resource "aws_s3_bucket" "db_migration" {
  bucket = local.db_migration_bucket_name

  tags = merge(local.tags, {
    Name    = local.db_migration_bucket_name
    Purpose = "CHAPS ${local.application_data.accounts[local.environment].environment_name} database migration"
  })
}

resource "aws_s3_bucket_public_access_block" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.db_migration.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id

  rule {
    id     = "expire-${local.application_data.accounts[local.environment].environment_name}-db-migration-backups"
    status = "Enabled"

    filter {
      prefix = "${local.db_migration_prefix}/"
    }

    expiration {
      days = 14
    }

    noncurrent_version_expiration {
      noncurrent_days = 14
    }
  }
}
