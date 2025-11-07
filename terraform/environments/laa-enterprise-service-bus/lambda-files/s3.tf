#####################################################################################
###### S3 Bucket for Lambda Zip Files, Layer files and Wallet files #################
#####################################################################################

resource "aws_s3_bucket" "lambda_files" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-lambda-files" }
  )
}

resource "aws_s3_bucket_public_access_block" "lambda_files" {
  bucket                  = aws_s3_bucket.lambda_files.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "lambda_files" {
  bucket = aws_s3_bucket.lambda_files.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lambda_files" {
  bucket = aws_s3_bucket.lambda_files.id
  versioning_configuration {
    status = "Enabled"
  }
}
