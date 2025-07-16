resource "aws_s3_bucket" "rekognition_bucket" {
  bucket = local.rekog_s3_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rekognition_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.rekognition_bucket.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}