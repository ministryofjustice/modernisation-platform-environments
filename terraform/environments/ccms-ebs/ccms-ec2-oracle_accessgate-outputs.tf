output "aws_instance_ec2_accessgate_arn" {
  description = "aws_instance ec2_accessgate arn"
  value       = aws_instance.ec2_accessgate[*].arn
}

output "aws_instance_ec2_accessgate_private_dns" {
  description = "aws_instance ec2_accessgate private_dns"
  value       = aws_instance.ec2_accessgate[*].private_dns
}

output "aws_instance_ec2_accessgate_private_ip" {
  description = "aws_instance ec2_accessgate private_ip"
  value       = aws_instance.ec2_accessgate[*].private_ip
}
