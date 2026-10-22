output "github_backup_destination" {
  description = "GitHub backup destination and existing consumer role; null outside production."
  value = local.is_production ? {
    parameter_name = aws_ssm_parameter.github_backup_destination[0].name
    s3_uri         = "s3://${module.github_backup_bucket[0].s3_bucket_id}"
    kms_key_arn    = module.github_backup_key[0].key_arn
    role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-management"
    account_id     = data.aws_caller_identity.current.account_id
    region         = data.aws_region.current.region
  } : null
}
