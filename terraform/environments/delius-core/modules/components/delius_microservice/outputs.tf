output "target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "service_security_group_id" {
  value = aws_security_group.ecs_service.id
}
