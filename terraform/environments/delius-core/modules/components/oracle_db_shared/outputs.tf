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
    "combined_instance_policy" = aws_iam_policy.combined_instance_policy
  }
}

output "database_application_passwords_secret_arn" {
  value = aws_secretsmanager_secret.database_application_passwords.arn
}

output "db_ec2_sg_id" {
  value = aws_security_group.db_ec2.id
}
