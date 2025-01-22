locals {

  access_logs = var.enable_access_logs ? {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "${var.alb_name}-${local.alb_suffix}"
  } : {}

  alb_suffix = var.internal ? "internal" : "external"
}
