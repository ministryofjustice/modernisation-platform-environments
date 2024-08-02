output "dms_s3_bucket_name" {
  value = {
    (var.env_name) = module.s3_bucket_dms_destination.bucket.bucket
  }
}