# ---------------------------------------------------------------------------------------------------------------------
# S3 - Inspector Findings Reports
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "inspector_reports" {
  #checkov:skip=CKV_AWS_18:access logs not required
  #checkov:skip=CKV_AWS_144:cross region replication not required
  #checkov:skip=CKV2_AWS_62:event notifications not required
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = "${local.name}-inspector-reports-${local.environment}"
  tags   = local.extended_tags
}

resource "aws_s3_bucket_versioning" "inspector_reports" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.inspector_reports[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inspector_reports" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.inspector_reports[0].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.inspector_s3[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "inspector_reports" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket                  = aws_s3_bucket.inspector_reports[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "inspector_reports" {
  count      = contains(local.deploy_to, local.environment) ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.inspector_reports]
  bucket     = aws_s3_bucket.inspector_reports[0].id

  rule {
    id     = "expire-old-reports"
    status = "Enabled"
    expiration {
      days = 365
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
