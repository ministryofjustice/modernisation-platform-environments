#####################################################################################
################## S3 Bucket for Lambda Layer Dependencies ##########################
#####################################################################################
resource "aws_s3_bucket" "lambda_layer_dependencies" {
  bucket = "lambda-layer-dependencies-${local.environment}"

  tags = merge(
    local.tags,
    { Name = "lambda-layer-dependencies-${local.environment}" }
  )
}

resource "aws_s3_object" "lambda_layer_zip" {
  bucket      = aws_s3_bucket.lambda_layer_dependencies.bucket
  key         = "cwa_extract_lambda/lambda_dependencies.zip"
  source      = "layers/lambda_dependencies.zip"
  source_hash = filemd5("layers/lambda_dependencies.zip")
}

resource "aws_s3_bucket_public_access_block" "lambda_layer_dependencies" {
  bucket                  = aws_s3_bucket.lambda_layer_dependencies.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "lambda_layer_dependencies" {
  bucket = aws_s3_bucket.lambda_layer_dependencies.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "lambda_layer_dependencies" {
  bucket = aws_s3_bucket.lambda_layer_dependencies.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.lambda_layer_dependencies
  ]
}

resource "aws_s3_bucket_versioning" "lambda_layer_dependencies" {
  bucket = aws_s3_bucket.lambda_layer_dependencies.id
  versioning_configuration {
    status = "Enabled"
  }
}

#####################################################################################
######################## S3 Bucket for Extracted Data ###############################
#####################################################################################

resource "aws_s3_bucket" "data" {
  bucket = "${local.application_name_short}-${local.environment}-cwa-extract-data"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-data"}
  )
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.data
  ]
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}