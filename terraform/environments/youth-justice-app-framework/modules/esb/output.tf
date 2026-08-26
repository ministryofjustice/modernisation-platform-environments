output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.esb.id
}

output "esb_security_group_id" {
  description = "Security Group ID for esb"
  value       = aws_security_group.esb_service.id
}

output "esb_instance_profile" {
  value = aws_iam_instance_profile.esb_ec2_profile.name
}

output "esb_instance_private_ip" {
  value = aws_instance.esb.private_ip
}

output "debug_ami" {
  value = var.ami # Referencing the variable directly
}