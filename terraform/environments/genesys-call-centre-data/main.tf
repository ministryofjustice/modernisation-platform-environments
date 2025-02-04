module "call_centre_landing" {
  source = "./modules/s3_bucket"
  bucket_name = var.s3_bucket_landing
  bucket_acl = var.acl
  sns_topic_arn = var.sns_topic_arn
  versioning_enabled = var.versioning_enabled
  logging_enabled = var.logging_enabled
}

module "call_centre_logs" {
  source = "./modules/s3_bucket"
  bucket_name = var.s3_bucket_logs
  bucket_acl = var.acl
  sns_topic_arn = var.sns_topic_arn
  versioning_enabled = var.versioning_enabled
  logging_enabled = var.logging_enabled
}