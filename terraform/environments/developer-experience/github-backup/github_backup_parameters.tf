resource "aws_ssm_parameter" "github_backup_destination" {
  count = local.is_production ? 1 : 0

  #checkov:skip=CKV_AWS_337:The backup destination URI is non-sensitive configuration.
  #checkov:skip=CKV2_AWS_34:The backup destination URI does not require a SecureString.
  name        = "/github-management/github-backup/s3-uri"
  description = "S3 destination for GitHub repository backup archives"
  type        = "String"
  value       = "s3://${module.github_backup_bucket[0].s3_bucket_id}"
}
