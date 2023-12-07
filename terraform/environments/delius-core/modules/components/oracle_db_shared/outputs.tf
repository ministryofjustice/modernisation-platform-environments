output "security_group" {
  value = aws_security_group.db_ec2
}

output "instance_profile" {
  value = aws_iam_instance_profile.db_ec2_instanceprofile
}

output "iam_role" {
  value = aws_iam_role.db_ec2_instance_iam_role
}

output "db_key_pair" {
  value = aws_key_pair.db_ec2_key_pair
}

output "db_ssh_key_ssm_parameter" {
  value = aws_ssm_parameter.ec2_user_ssh_key
}