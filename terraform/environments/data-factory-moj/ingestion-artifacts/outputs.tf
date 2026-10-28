output "artifact_bucket_name" {
  description = "Deployment artifact bucket name, or null outside development."
  value       = try(aws_s3_bucket.artifacts["packages"].id, null)
}

output "artifact_bucket_arn" {
  description = "Deployment artifact bucket ARN, or null outside development."
  value       = try(aws_s3_bucket.artifacts["packages"].arn, null)
}

output "artifact_kms_key_arn" {
  description = "Artifact encryption key ARN, or null outside development."
  value       = one(aws_kms_key.artifacts[*].arn)
}

output "artifact_access_log_bucket_name" {
  description = "Artifact access-log bucket name, or null outside development."
  value       = try(aws_s3_bucket.artifacts["access_logs"].id, null)
}
