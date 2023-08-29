output "aws_instance_ec2_ftp_arn" {
  description = "aws_instance ec2_ftp arn"
  value       = aws_instance.ec2_ftp.arn
}

output "aws_instance_ec2_ftp_private_dns" {
  description = "aws_instance ec2_ftp private_dns"
  value       = aws_instance.ec2_ftp.private_dns
}

output "aws_instance_ec2_ftp_private_ip" {
  description = "aws_instance ec2_ftp private_ip"
  value       = aws_instance.ec2_ftp.private_ip
}
