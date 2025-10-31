output "aws_instance_ec2_clamav_arn" {
  description = "aws_instance ec2_clamav arn"
  value       = aws_instance.ec2_clamav.arn
}

output "aws_instance_ec2_clamav_private_dns" {
  description = "aws_instance ec2_clamav private_dns"
  value       = aws_instance.ec2_clamav.private_dns
}

output "aws_instance_ec2_clamav_private_ip" {
  description = "aws_instance ec2_clamav private_ip"
  value       = aws_instance.ec2_clamav.private_ip
}
