resource "aws_s3_bucket" "connector_docs" {
  bucket = "${local.component_name}-${local.env_label}-docs"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-docs"
  })
}

resource "aws_s3_bucket_versioning" "connector_docs" {
  bucket = aws_s3_bucket.connector_docs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "connector_docs" {
  bucket = aws_s3_bucket.connector_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.general_shared.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "connector_docs" {
  bucket                  = aws_s3_bucket.connector_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
