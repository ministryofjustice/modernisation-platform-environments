
output "ecs_service_external_sg_id" {
  description = "The ID of the securiy group that controlls access to External ECS microservices (i.e the Gateway)."
  value       = aws_security_group.common_ecs_service_external.id
}

output "ecs_service_internal_sg_id" {
  description = "The ID of the securiy group that controlls access to Internal ECS microservices (i.e the Gateway)."
  value       = aws_security_group.common_ecs_service_internal.id
}