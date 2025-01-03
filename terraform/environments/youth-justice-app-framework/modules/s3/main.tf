resource "aws_s3_bucket" "default" {
  for_each = toset(var.bucket_name)
  bucket   = each.value
  tags     = var.tags
}

resource "aws_s3_bucket_ownership_controls" "default" {
  for_each = toset(var.bucket_name)
  bucket   = aws_s3_bucket.default[each.value].id
  rule {
    object_ownership = var.ownership_controls
  }
}

resource "aws_s3_bucket_acl" "default" {
  for_each = toset(var.bucket_name)
  bucket   = aws_s3_bucket.default[each.value].id
  acl      = var.acl
  depends_on = [
    aws_s3_bucket_ownership_controls.default
  ]
}

resource "aws_s3_bucket_public_access_block" "default" {
  for_each                = toset(var.bucket_name)
  bucket                  = aws_s3_bucket.default[each.value].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "default" {
  for_each = var.log_bucket != null ? toset(var.bucket_name) : []
  bucket   = aws_s3_bucket.default[each.value].id

  target_bucket = var.log_bucket
  target_prefix = aws_s3_bucket.default[each.value].bucket
}
