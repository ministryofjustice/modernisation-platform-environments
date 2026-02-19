resource "aws_s3_bucket" "bucket" {
  provider = aws.us-east-1
  bucket_prefix = "mike-reid-testing-abc123789"
  force_destroy = true
  tags = {
    Name        = "mike-reid-testing-abc123789"
    Environment = "development"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}