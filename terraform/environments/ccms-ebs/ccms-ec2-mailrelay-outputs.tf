output "aws_instance_ec2_mailrelay_private_ip" {
  description = "aws_instance ec2_mailrelay private_ip"
  value       = aws_instance.ec2_mailrelay.private_ip
}
