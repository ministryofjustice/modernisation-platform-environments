output "github-backup-destination" {
  description = "GitHub backup destination and existing consumer role; null outside production."
  value = local.is-production ? {
    parameter_name = aws_ssm_parameter.github-backup-destination[0].name
    s3_uri         = "s3://${module.github-backup[0].s3_bucket_id}"
    kms_key_arn    = module.github-backup-key[0].key_arn
    role_arn       = module.iam_role[0].arn
    account_id     = data.aws_caller_identity.current.account_id
    region         = data.aws_region.current.region
  } : null
}
