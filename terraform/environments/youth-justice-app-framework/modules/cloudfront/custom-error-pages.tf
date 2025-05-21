resource "aws_s3_bucket" "error_page" {
  bucket = "yjaf-${var.environment}-custom-error-pages"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "error_page_public" {
  bucket = aws_s3_bucket.error_page.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "custom_503" {
  bucket       = aws_s3_bucket.error_page.id
  key          = "custom-503.html"
  source       = "custom-503.html" # Local file
  content_type = "text/html"
  acl          = "private"
}

resource "aws_s3_bucket_policy" "error_page_policy" {
  bucket = aws_s3_bucket.error_page.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.error_page.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for private S3 access"
}