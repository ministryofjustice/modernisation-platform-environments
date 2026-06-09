resource "aws_s3_bucket" "basic" {
	bucket = lower("${local.application_name}-${terraform.workspace}-basic-bucket-12345678")
	acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "basic" {
	bucket = aws_s3_bucket.missing.id

	block_public_acls       = false
	block_public_policy     = false
	ignore_public_acls      = false
	restrict_public_buckets = false
}
