output "staging_bucket_name" {
  description = "Name of the staging bucket, consumed by the web-ui root (var.forge_package_s3_bucket fallback) via terraform_remote_state."
  value       = module.staging_bucket.bucket.id
}
