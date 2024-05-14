resource "aws_s3_bucket" "dms_target_ep_s3_bucket" {
  #checkov:skip=CKV_AWS_144:Unsure of policy on this yet, should be covered by module - See ELM-1949
  #checkov:skip=CKV_AWS_145:Decide on a KMS key for encryption, should be covered by moudle - See ELM-1949
  bucket_prefix = "dms-rds-to-csv-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Target Endpoint S3 Bucket",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "dms_target_ep_s3_bucket" {
  bucket                  = aws_s3_bucket.dms_target_ep_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_target_ep_s3_bucket" {
  bucket = aws_s3_bucket.dms_target_ep_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dms_target_ep_s3_bucket" {
  bucket = aws_s3_bucket.dms_target_ep_s3_bucket.id
  policy = data.aws_iam_policy_document.dms_target_ep_s3_bucket.json
}
