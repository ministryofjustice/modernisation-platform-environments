output "bucket_id" {
  value = module.this-bucket.bucket.id
}

output "bucket_arn" {
  value = module.this-bucket.bucket.arn
}

output "replication_role_arn" {
  value = aws_iam_role.replication_role[0].arn
}
