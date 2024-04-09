resource "aws_s3_bucket" "dms_target_ep_s3_bucket" {
  bucket_prefix = "dms-rds-to-parquet-"

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
