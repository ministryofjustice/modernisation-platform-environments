#####################################################################################
######################## S3 Bucket for Extracted Data ###############################
#####################################################################################

resource "aws_s3_bucket" "patch_data" {
  count  = local.environment == "test" ? 1 : 0
  bucket = "${local.application_name_short}-${local.environment}-patch-cwa-extract-data"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-data" }
  )
}

resource "aws_s3_bucket_public_access_block" "patch_data" {
  count                   = local.environment == "test" ? 1 : 0
  bucket                  = aws_s3_bucket.patch_data[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "patch_data" {
  count  = local.environment == "test" ? 1 : 0
  bucket = aws_s3_bucket.patch_data[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "patch_data" {
  count  = local.environment == "test" ? 1 : 0
  bucket = aws_s3_bucket.patch_data[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
