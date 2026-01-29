output "bucket_id" {
  value = module.this-bucket.bucket.id
}

output "bucket_arn" {
  value = module.this-bucket.bucket.arn
}

output "replication_role_arn" {
  value = local.replication_enabled ? aws_iam_role.replication_role[0].arn : null
}

output "manifest_bucket" {
  value = aws_s3_bucket.default
}
