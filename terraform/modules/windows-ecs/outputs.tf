output "cluster_ec2_security_group_id" {
  description = "Security group id of EC2s used for ECS cluster"
  value = aws_security_group.cluster_ec2.id
}
