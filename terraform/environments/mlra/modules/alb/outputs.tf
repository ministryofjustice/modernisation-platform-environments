output "athena_db" {
  value = aws_athena_database.lb-access-logs
}

output "security_group" {
  value = aws_security_group.lb
}

output "load_balancer" {
  value = aws_lb.loadbalancer
}
