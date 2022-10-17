# output "athena_db" {
#   value = aws_athena_database.lb-access-logs
# }

# output "security_group" {
#   value = aws_security_group.lb
# }

# output "load_balancer" {
#   value = aws_lb.loadbalancer
# }

# output "aws_lb_listener" {
#   value = aws_lb.listener
# }

# output "aws_lb_target_group" {
#   value = aws_lb.loadbalancer
# }

output "athena_db" {
  value = module.lb-access-logs-enabled.athena_db
}

output "security_group" {
  value = module.lb-access-logs-enabled.security_group
}

output "load_balancer" {
  value = module.lb-access-logs-enabled.load_balancer
}
