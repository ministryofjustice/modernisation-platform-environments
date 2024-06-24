output "security_group" {
  value = aws_security_group.db_ec2
}

output "db_key_pair" {
  value = aws_key_pair.db_ec2_key_pair
}

output "db_ssh_key_ssm_parameter" {
  value = aws_ssm_parameter.ec2_user_ssh_key
}

output "ssh_keys_bucket_name" {
  value = module.s3_bucket_ssh_keys.bucket.id
}

output "instance_policies" {
  value = {
    "core_shared_services_bucket_access"  = aws_iam_policy.core_shared_services_bucket_access
    "allow_access_to_ssm_parameter_store" = aws_iam_policy.allow_access_to_ssm_parameter_store
    "ec2_access_for_ansible"              = aws_iam_policy.ec2_access_for_ansible
    "db_access_to_secrets_manager"        = aws_iam_policy.db_access_to_secrets_manager
    "oracledb_backup_bucket_access"       = aws_iam_policy.oracledb_backup_bucket_access
    "db_ssh_keys_s3"                      = aws_iam_policy.db_ssh_keys_s3
    "instance_ssm"                        = aws_iam_policy.instance_ssm
  }
}

output "database_application_passwords_secret_arn" {
  value = aws_secretsmanager_secret.database_application_passwords.arn
}
