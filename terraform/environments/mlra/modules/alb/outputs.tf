output "target_group_name" {
  description = "Output ALB target group name to be picked up by module cwalarm"
  value       = aws_lb_target_group.alb_target_group.name
}

output "target_group_arn" {
  description = "Output ALB target group ARN to be picked up by module mlra-ecs"
  value       = aws_lb_target_group.alb_target_group.arn
}

# output "loab_balancer_listener" {
#   value = aws_lb_listener.alb_listener
# }

output "athena_db" {
  value = aws_athena_database.lb-access-logs
}

output "security_group" {
  value = aws_security_group.lb
}

output "load_balancer" {
  value = aws_lb.loadbalancer
}
