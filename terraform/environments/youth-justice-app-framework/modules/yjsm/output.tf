output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.yjsm.id
}

output "yjsm_security_group_id" {
  description = "Security Group ID for YJSM"
  value       = aws_security_group.yjsm_service.id
}

output "yjsm_instance_profile" {
  value = aws_iam_instance_profile.yjsm_ec2_profile.name
}

output "yjsm_instance_private_ip" {
  value = aws_instance.yjsm.private_ip
}

output "private_key_pem" {
  value     = module.key_pair.private_key_pem
  sensitive = true
}