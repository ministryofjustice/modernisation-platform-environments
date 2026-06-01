resource "aws_s3_bucket" "basic" {
	bucket = lower("${local.application_name}-${terraform.workspace}-basic-bucket-12345678")
}

resource "aws_s3_bucket_public_access_block" "basic" {
	bucket = aws_s3_bucket.basic.id

	block_public_acls       = true
	block_public_policy     = true
	ignore_public_acls      = true
	restrict_public_buckets = true
}
