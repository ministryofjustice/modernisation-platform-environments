output "tribunals_lb_sc_id" {
  description = "LB Security Group Id"
  value       = aws_security_group.tribunals_lb_sc.id
}