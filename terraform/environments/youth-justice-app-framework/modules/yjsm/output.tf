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

output "yjsm_instance_secondary_private_ip" {
  value = aws_network_interface.main.private_ip_list[1]
}

output "private_key_pem" {
  value     = module.key_pair.private_key_pem
  sensitive = true
}

output "juniper_cug_prefix_list_id" {
  description = "Managed prefix list ID for the YJB CUG range Juniper reaches yjsm on"
  value       = aws_ec2_managed_prefix_list.custom_internal.id
}