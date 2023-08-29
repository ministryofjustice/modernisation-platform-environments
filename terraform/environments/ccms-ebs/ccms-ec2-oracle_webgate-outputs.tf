output "aws_instance_ec2_webgate_arn" {
  description = "aws_instance ec2_webgate arn"
  value       = aws_instance.ec2_webgate[*].arn
}

output "aws_instance_ec2_webgate_private_dns" {
  description = "aws_instance ec2_webgate private_dns"
  value       = aws_instance.ec2_webgate[*].private_dns
}

output "aws_instance_ec2_webgate_private_ip" {
  description = "aws_instance ec2_webgate private_ip"
  value       = aws_instance.ec2_webgate[*].private_ip
}
