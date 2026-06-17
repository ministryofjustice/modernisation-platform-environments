resource "aws_s3_object" "source_bucket" {
  bucket                 = data.aws_s3_bucket.source_bucket.id
  key                    = var.s3_source_key
  source                 = var.source_file_name
  server_side_encryption = "aws:kms"
}