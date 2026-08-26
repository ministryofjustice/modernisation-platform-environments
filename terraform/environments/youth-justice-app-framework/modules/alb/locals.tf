locals {

  access_logs = var.enable_access_logs ? {
    bucket = module.log_bucket.s3_bucket_id
  } : {}

  alb_suffix = var.internal ? "internal" : "external"
}
