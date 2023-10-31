output "tribunals_lb_sc_id" {
  description = "LB Security Group Id"
  value       = aws_security_group.tribunals_lb_sc.id
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


