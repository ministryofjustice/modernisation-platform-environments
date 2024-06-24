output "tribunals_lb_sc_id" {
  description = "LB Security Group Id"
  value       = aws_security_group.tribunals_lb_sc.id
}

output "tribunals_lb_sc" {
  description = "LB Security Group"
  value       = aws_security_group.tribunals_lb_sc
}

output "tribunals_target_group_arn" {
  description = "LB Target Group arn"
  value       = aws_lb_target_group.tribunals_target_group.arn
}

output "tribunals_lb_listener" {
  description = "LB Listener"
  value       = aws_lb_listener.tribunals_lb
}

output "tribunals_lb" {
  description = "LB"
  value       = aws_lb.tribunals_lb
}

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
