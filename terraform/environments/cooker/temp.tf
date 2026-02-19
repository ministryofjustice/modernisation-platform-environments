resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "mike-reid-testing-abc1234"
  force_destroy = true
  tags = {
    Name        = "mike-reid-testing-abc1234"
    Environment = "development"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  bucket   = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}