##################################
### S3 for Backup Lambda
##################################

resource "aws_s3_bucket" "scripts" {
  bucket = "${local.application_name_short}-${local.environment}-scripts"
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-scripts" }
  )
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}
