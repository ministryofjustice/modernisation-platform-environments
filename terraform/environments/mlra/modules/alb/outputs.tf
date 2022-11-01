output "athena_db" {
  value = module.lb-access-logs-enabled.athena_db
}

output "security_group" {
  value = module.lb-access-logs-enabled.security_group
}

output "load_balancer" {
  value = module.lb-access-logs-enabled.load_balancer
}

output "target_group_name" {
  value = aws_lb_target_group.alb_target_group.name
}
