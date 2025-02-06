# S3 Bucket - Staging
# TODO...

# S3 Bucket - Landing
module "s3_landing_bucket" {
  source             = "./modules/s3"
  bucket_name        = var.s3_bucket_landing
  # bucket_acl         = var.acl
  versioning_enabled = var.versioning_enabled
  # logging_enabled    = var.logging_enabled
  force_destroy      = var.force_destroy
}

# S3 Bucket - Logs
module "s3_logs_bucket" {
  source             = "./modules/s3"
  bucket_name        = var.s3_bucket_logs
  # bucket_acl         = var.acl
  versioning_enabled = var.versioning_enabled
  # logging_enabled    = var.logging_enabled
  force_destroy      = var.force_destroy
}

# S3 Bucket - Archive
# TODO...

# S3 Bucket - Ingestion
# TODO...

# S3 Bucket - Curated
# TODO...
