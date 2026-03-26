#####################################################################################
###### S3 Bucket for Lambda Zip Files, Layer files and Wallet files #################
#####################################################################################

resource "aws_s3_bucket" "image_files" {
  count = local.environment == "development" ? 1 : 0

  bucket = "${local.application_name}-${local.environment}-image-files"

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-image-files" }
  )
}

resource "aws_s3_bucket_public_access_block" "image_files" {
  count = local.environment == "development" ? 1 : 0

  bucket                  = aws_s3_bucket.image_files[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "image_files" {
  count = local.environment == "development" ? 1 : 0

  bucket = aws_s3_bucket.image_files[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "image_files" {
  count = local.environment == "development" ? 1 : 0

  bucket = aws_s3_bucket.image_files[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

