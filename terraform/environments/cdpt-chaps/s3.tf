resource "aws_s3_bucket" "chaps-db-backup-bucket" {
	bucket = local.app_data.accounts[local.environment].s3_bucket_name
}

