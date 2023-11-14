resource "aws_s3_bucket" "laa-lambda-backup" {
  bucket = var.bucket_name
  tags   = var.tags
}


resource "aws_s3_object" "provision_files" {
  bucket       = aws_s3_bucket.laa-lambda-backup.id
  for_each     = fileset("./zipfiles/", "**")
  key          = each.value
  source       = "./zipfiles/${each.value}"
  content_type = each.value
}




resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.laa-lambda-backup.id
  rule {
    object_ownership = var.ownership_controls
  }
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.laa-lambda-backup.id
  acl    = var.acl
  depends_on = [
    aws_s3_bucket_ownership_controls.default
  ]
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.laa-lambda-backup.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "laa-lambda-backup-versioning" {
  bucket = aws_s3_bucket.laa-lambda-backup.id
  versioning_configuration {
    status = "Enabled"
  }
}
