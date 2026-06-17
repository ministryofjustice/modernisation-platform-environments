data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "source_bucket" {
  bucket = var.s3_source_bucket
}

data "aws_s3_object" "source_file" {
  bucket = var.s3_source_bucket
  key    = var.s3_source_key
}
