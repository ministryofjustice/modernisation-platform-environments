output "security_group_id" {
  value = var.enable_compute_node ? aws_security_group.ec2_sec_group[0].id : ""
}