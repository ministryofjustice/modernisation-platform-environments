output "tribunals_lb_ftp" {
  description = "SFTP LB"
  value       = aws_lb.tribunals_lb_ftp
}

output "sftp_tribunals_target_group_arn" {
  description = "Network Load Balancer Target Group ARN for SFTP connections"
  value       = length(aws_lb_target_group.tribunals_target_group_sftp) > 0 ? aws_lb_target_group.tribunals_target_group_sftp[0].arn : ""
}

output "tribunals_lb_sc_id_sftp" {
  description = "Network LB Security Group Id for sftp"
  value       = length(aws_security_group.tribunals_lb_sc_sftp) > 0 ? aws_security_group.tribunals_lb_sc_sftp[0].id : ""
}
