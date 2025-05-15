resource "aws_s3_bucket" "test_bucket" {
  bucket_prefix = var.bucket_prefix
  tags          = var.tags
}
