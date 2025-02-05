# S3 Landing Bucket
module "s3_landing_bucket" {
  source = "./modules/s3_bucket"
  bucket_name = var.s3_bucket_landing
  bucket_acl = var.acl
  versioning_enabled = var.versioning_enabled
  logging_enabled = var.logging_enabled
}

# S3 Logs Bucket
module "s3_logs_bucket" {
  source = "./modules/s3_bucket"
  bucket_name = var.s3_bucket_logs
  bucket_acl = var.acl
  versioning_enabled = var.versioning_enabled
  logging_enabled = var.logging_enabled
}