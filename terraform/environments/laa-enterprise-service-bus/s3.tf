resource "aws_s3_bucket" "lambda_layer_dependencies" {
  bucket = "lambda-layer-dependencies-${local.environment}"

  tags = merge(
    local.tags,
    { Name = "lambda-layer-dependencies-${local.environment}" }
  )
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